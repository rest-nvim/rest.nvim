---@mod rest-nvim.client.curl.cli rest.nvim cURL cli client
---
---@brief [[
---
--- rest.nvim cURL cli client implementation
--- heavily inspired by plenary.nvim
---
---@brief ]]

local curl = {}

local nio = require("nio")
local log = require("rest-nvim.logger")
local curl_utils = require("rest-nvim.client.curl.utils")
local progress = require("fidget.progress")

---@see vim.system
---@param args string[] curl CLI arguments
---@param on_exit fun(sc: vim.SystemCompleted) Called asynchronously when the luarocks command exits. asynchronously. Receives SystemCompleted object, see return of SystemObj:wait().
---@param opts? vim.SystemOpts
---@package
---@diagnostic disable-next-line: unused-local
function curl.cli(args, on_exit, opts) end

curl.cli = nio.create(function(args, on_exit, opts)
  opts = opts or {}
  opts.detach = false
  opts.text = true
  -- TODO(boltless): parse by chunk using `--trace-ascii %`
  local curl_cmd = { "curl", "-sL", "--trace-time", "-v" }
  curl_cmd = vim.list_extend(curl_cmd, args)
  log.info(curl_cmd)
  opts.detach = false
  local ok, e = pcall(vim.system, curl_cmd, opts, on_exit)
  if not ok then
    ---@type vim.SystemCompleted
    local sc = {
      code = 99999,
      signal = 0,
      stderr = "Failed to invoke curl: " .. e,
    }
    on_exit(sc)
  end
end, 3)

local parser = {}

---@package
---@param str string
---@return {version:string,code:number,status:string}
function parser.parse_verbose_status(str)
  local version, code = str:match("^(%S+) (%d+)")
  return {
    version = version,
    code = tonumber(code),
    -- status = status,
  }
end

---@package
---@param str string
---@return string? key
---@return string? value
function parser.parse_header_pair(str)
  local key, value = str:match("(%S+):(.*)")
  if not key then
    return
  end
  return key, vim.trim(value)
end

---@package
---@param line string
---@return {time:string,prefix:string,str:string?}|nil
function parser.parse_verbose_line(line)
  local time, prefix, str = line:match("(%S+) (.) ?(.*)")
  if not time then
    return
  end
  return {
    time = time,
    prefix = prefix,
    str = str,
  }
end

local VERBOSE_PREFIX_META = "*"
local VERBOSE_PREFIX_REQ_HEADER = ">"
local VERBOSE_PREFIX_REQ_BODY = "}"
local VERBOSE_PREFIX_RES_HEADER = "<"
local VERBOSE_PREFIX_RES_BODY = "{"

---@param lines string[]
function parser.parse_verbose(lines)
  local response = {
    headers = {},
  }
  vim.iter(lines):map(parser.parse_verbose_line):each(function(ln)
    if ln.prefix == VERBOSE_PREFIX_META then
    elseif ln.prefix == VERBOSE_PREFIX_REQ_HEADER then
    elseif ln.prefix == VERBOSE_PREFIX_REQ_BODY then
    elseif ln.prefix == VERBOSE_PREFIX_RES_HEADER then
      if not response.status then
        -- response status
        response.status = parser.parse_verbose_status(ln.str)
      else
        -- response header
        local key, value = parser.parse_header_pair(ln.str)
        if key then
          response.headers[key:lower()] = value
        end
      end
    elseif ln.prefix == VERBOSE_PREFIX_RES_BODY then
      -- we don't parse body here
      -- body is sent to stdout while other verbose logs are sent to stderr
    end
  end)
  return response
end

---@param kv table<string,string>
---@return string[]
local function kv_to_list(kv, prefix, sep)
  local tbl = {}
  for key, value in pairs(kv) do
    table.insert(tbl, prefix)
    table.insert(tbl, key .. sep .. value)
  end
  return tbl
end

---@private
local builder = {}

---@param method string
---@return string[] args
function builder.method(method)
  if method ~= "head" then
    return { "-X", string.upper(method) }
  else
    return { "-I" }
  end
end

---@package
---@param header table<string,string>
---@return string[] args
function builder.headers(header)
  return kv_to_list(
    (function()
      local upper = function(str)
        return string.gsub(" " .. str, "%W%l", string.upper):sub(2)
      end
      local normilzed = {}
      for k, v in pairs(header) do
        normilzed[upper(k:gsub("_", "%-"))] = v
      end
      return normilzed
    end)(),
    "-H",
    ": "
  )
end

---@param body string?
---@return string[]? args
function builder.raw_body(body)
  if not body then
    return
  end
  return { "--data-raw", body }
end

---@package
---@param body table<string,string>?
---@return string[]? args
function builder.data_body(body)
  if not body then
    return
  end
  return kv_to_list(body, "-d", "=")
end

---@package
---@param form table<string,string>?
---@return string[]? args
function builder.form(form)
  if not form then
    return
  end
  return kv_to_list(form, "-F", "=")
end

function builder.file(file)
  if not file then
    return
  end
  -- FIXME: should normalize/expand the file path
  return { "-d", "@" .. file }
end

---@package
---@param version string
---@return string[]? args
function builder.http_version(version)
  vim.validate({
    version = {
      version,
      function(v)
        return not v or vim.list_contains({ "HTTP/0.9", "HTTP/1.0", "HTTP/1.1", "HTTP/2", "HTTP/3" }, v)
      end,
    },
  })
  if not version then
    return
  end
  return { "--" .. version:lower():gsub("/", "") }
end

---build curl request arguments based on Request object
---@param request Request
---@return string[] args
function builder.build(request)
  local args = {}
  table.insert(args, request.url)
  table.insert(args, builder.method(request.method))
  table.insert(args, builder.headers(request.headers))
  -- TODO: body
  -- TODO: auth?
  builder.http_version(request.http_version)
  return vim.iter(args):flatten():totable()
end

---returns future containing Result
---@param request Request Request data to be passed to cURL
---@return nio.control.Future
function curl.request(request)
  local progress_handle = progress.handle.create({
    title = "Fetching",
    lsp_client = { name = "rest.nvim" },
  })
  local future = nio.control.future()
  local args = builder.build(request)
  curl.cli(args, function(sc)
    if sc.code ~= 0 then
      local message = "Something went wrong when making the request with cURL:\n" .. curl_utils.curl_error(sc.code)
      progress_handle:cancel()
      log.error(message)
      future.set_error(message)
      return
    end
    vim.schedule(function ()
      progress_handle:report({
        message = "parsing response",
      })
    end)
    local response = parser.parse_verbose(vim.split(sc.stderr, "\n"))
    response.body = sc.stdout
    future.set(response)
    vim.schedule(function ()
    progress_handle:finish()
    end)
  end, {
    -- TODO(boltless): parse by chunk from here
    -- stdout = function (err, chunk) end,
    -- stderr = function (err, chunk) end,
  })
  return future
end

curl.builder = builder
curl.parser = parser

return curl
