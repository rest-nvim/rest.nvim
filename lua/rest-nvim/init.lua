local backend = require("rest-nvim.request")
local config = require("rest-nvim.config")
local curl = require("rest-nvim.curl")
local log = require("plenary.log").new({ plugin = "rest.nvim" })
local utils = require("rest-nvim.utils")
local path = require("plenary.path")

local rest = {}
local Opts = {}
local defaultRequestOpts = {
  verbose = false,
  highlight = false,
}

local LastOpts = {}

rest.setup = function(user_configs)
  config.set(user_configs or {})
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
-- @param verbose toggles if only a dry run with preview should be executed (true = preview)
rest.run = function(verbose)
  local ok, result = backend.get_current_request()
  if not ok then
    log.error("Failed to run the http request:")
    log.error(result)
    vim.api.nvim_err_writeln("[rest.nvim] Failed to get the current HTTP request: " .. result)
    return
  end

  return rest.run_request(result, { verbose = verbose })
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
-- @param string filename to load
-- @param opts table
--           1. keep_going boolean keep running even when last request failed
--           2. verbose boolean
rest.run_file = function(filename, opts)
  log.info("Running file :" .. filename)
  opts = vim.tbl_deep_extend(
    "force", -- use value from rightmost map
    defaultRequestOpts,
    { highlight = config.get("highlight").enabled },
    opts or {}
  )

  -- 0 on error or buffer handle
  local new_buf = vim.api.nvim_create_buf(true, false)

  vim.api.nvim_win_set_buf(0, new_buf)
  vim.cmd.edit(filename)

  local requests = backend.buf_list_requests(new_buf)
  for _, req in pairs(requests) do
    rest.run_request(req, opts)
  end

  return true
end

-- replace variables in header values
local function splice_headers(headers)
  for name, value in pairs(headers) do
    headers[name] = utils.replace_vars(value)
  end
  return headers
end

-- return the spliced/resolved filename
-- @param string the filename w/o variables
local function load_external_payload(fileimport_string)
  local fileimport_spliced = utils.replace_vars(fileimport_string)
  if path:new(fileimport_spliced):is_absolute() then
    return fileimport_spliced
  else
    local file_dirname = vim.fn.expand("%:p:h")
    local file_name = path:new(path:new(file_dirname), fileimport_spliced)
    return file_name:absolute()
  end
end


-- @param headers table  HTTP headers
-- @param payload table of the form { external = bool, filename_tpl= path, body_tpl = string }
--                 with body_tpl an array of lines
local function splice_body(headers, payload)
  local external_payload = payload.external
  local lines -- array of strings
  if external_payload then
    local importfile = load_external_payload(payload.filename_tpl)
    if not utils.file_exists(importfile) then
      error("import file " .. importfile .. " not found")
    end
    -- TODO we dont necessarily want to load the file, it can be slow
    -- https://github.com/rest-nvim/rest.nvim/issues/203
    lines = utils.read_file(importfile)
  else
    lines = payload.body_tpl
  end
  local content_type = ""
  for key, val in pairs(headers) do
    if string.lower(key) == "content-type" then
      content_type = val
      break
    end
  end
  local has_json = content_type:find("application/[^ ]*json")

  local body = ""
  local vars = utils.read_variables()
  -- nvim_buf_get_lines is zero based and end-exclusive
  -- but start_line and stop_line are one-based and inclusive
  -- magically, this fits :-) start_line is the CRLF between header and body
  -- which should not be included in the body, stop_line is the last line of the body
  for _, line in ipairs(lines) do
    body = body .. utils.replace_vars(line, vars)
  end

  local is_json, json_body = pcall(vim.json.decode, body)

  if is_json and json_body then
    if has_json then
      -- convert entire json body to string.
      return vim.fn.json_encode(json_body)
    else
      -- convert nested tables to string.
      for key, val in pairs(json_body) do
        if type(val) == "table" then
          json_body[key] = vim.fn.json_encode(val)
        end
      end
      return vim.fn.json_encode(json_body)
    end
  end
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
-- @param req table see validate_request to check the expected format
-- @param opts table
--           1. keep_going boolean keep running even when last request failed
rest.run_request = function(req, opts)
  -- TODO rename result to request
  local result = req
  local curl_raw_args = config.get("skip_ssl_verification") and vim.list_extend(result.raw, { "-k" })
      or result.raw
  opts = vim.tbl_deep_extend(
    "force", -- use value from rightmost map
    defaultRequestOpts,
    { highlight = config.get("highlight").enabled },
    opts or {}
  )

  -- if we want to pass as a file, we pass nothing to plenary
  local spliced_body = nil
  if not req.body.inline and req.body.filename_tpl then
    curl_raw_args = vim.tbl_extend("force", curl_raw_args, {
      '--data-binary', '@'..load_external_payload(req.body.filename_tpl)})
  else
    spliced_body = splice_body(result.headers, result.body)
  end

  Opts = {
    request_id = vim.loop.now(), -- request id used to correlate RestStartRequest and RestStopRequest events
    method = result.method:lower(),
    url = result.url,
    -- plenary.curl can't set http protocol version
    -- http_version = result.http_version,
    headers = splice_headers(result.headers),
    raw = curl_raw_args,
    body = spliced_body,
    dry_run = opts.verbose,
    bufnr = result.bufnr,
    start_line = result.start_line,
    end_line = result.end_line,
    script_str = result.script_str,
  }

  if not opts.verbose then
    LastOpts = Opts
  end

  if opts.highlight then
    backend.highlight(result.bufnr, result.start_line, result.end_line)
  end

  local success_req, req_err = pcall(curl.curl_cmd, Opts)

  if not success_req then
    vim.api.nvim_err_writeln(
      "[rest.nvim] Failed to perform the request.\nMake sure that you have entered the proper URL and the server is running.\n\nTraceback: "
        .. req_err
    )
    return false, req_err
  end
end

-- last will run the last curl request, if available
rest.last = function()
  if LastOpts.url == nil then
    vim.api.nvim_err_writeln("[rest.nvim]: Last request not found")
    return
  end

  if config.get("highlight").enabled then
    backend.highlight(LastOpts.bufnr, LastOpts.start_line, LastOpts.end_line)
  end

  local success_req, req_err = pcall(curl.curl_cmd, LastOpts)

  if not success_req then
    vim.api.nvim_err_writeln(
      "[rest.nvim] Failed to perform the request.\nMake sure that you have entered the proper URL and the server is running.\n\nTraceback: "
        .. req_err
    )
  end
end

rest.request = backend

rest.select_env = function(env_file)
  if path ~= nil then
    vim.validate({ env_file = { env_file, "string" } })
    config.set({ env_file = env_file })
  else
    print("No path given")
  end
end

return rest
