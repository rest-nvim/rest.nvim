local utils = require("rest-nvim.utils")
local log = require("plenary.log").new({ plugin = "rest.nvim" })
local config = require("rest-nvim.config")

-- get_importfile returns in case of an imported file the absolute filename
-- @param bufnr Buffer number, a.k.a id
-- @param stop_line Line to stop searching
-- @return tuple filename and whether we should inline it when invoking curl
local function get_importfile_name(bufnr, start_line, stop_line)
  -- store old cursor position
  local oldpos = vim.fn.getcurpos()
  utils.move_cursor(bufnr, start_line)

  local import_line = vim.fn.search("^<", "cn", stop_line)
  -- restore old cursor position
  utils.move_cursor(bufnr, oldpos[2])

  if import_line > 0 then
    local fileimport_string
    local fileimport_line
    local fileimport_inlined
    fileimport_line = vim.api.nvim_buf_get_lines(bufnr, import_line - 1, import_line, false)
    -- check second char against '@' (meaning "dont inline")
    fileimport_inlined = string.sub(fileimport_line[1], 2, 2) ~= '@'
    fileimport_string = string.gsub(fileimport_line[1], "<@?", "", 1):gsub("^%s+", ""):gsub("%s+$", "")
    return fileimport_inlined, fileimport_string

  end
  return nil
end

-- get_body retrieves the body lines in the buffer and then returns
-- either a table if the body is a JSON or a raw string if it is a filename
-- Plenary.curl allows a table or a raw string as body and can distinguish
-- between strings with filenames and strings with the raw body
-- @param bufnr Buffer number, a.k.a id
-- @param start_line Line where body starts
-- @param stop_line Line where body stops
-- @return table { external = bool; filename_tpl or body_tpl; }
local function get_body(bufnr, start_line, stop_line)
  -- first check if the body should be imported from an external file
  local inline, importfile = get_importfile_name(bufnr, start_line, stop_line)
  local lines -- an array of strings
  if importfile ~= nil then
    return { external = true; inline = inline; filename_tpl = importfile }
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, start_line, stop_line, false)
  end

  -- nvim_buf_get_lines is zero based and end-exclusive
  -- but start_line and stop_line are one-based and inclusive
  -- magically, this fits :-) start_line is the CRLF between header and body
  -- which should not be included in the body, stop_line is the last line of the body
  local lines2 = {}
  for _, line in ipairs(lines) do
    -- stop if a script opening tag is found
    if line:find("{%%") then
      break
    end
    -- Ignore commented lines with and without indent
    if not utils.contains_comments(line) then
      lines2[#lines2 + 1] = line
    end
  end

  return { external = false; inline = false; body_tpl = lines2 }
end

local function get_response_script(bufnr, start_line, stop_line)
  local all_lines = vim.api.nvim_buf_get_lines(bufnr, start_line, stop_line, false)
  -- Check if there is a script
  local script_start_rel
  for i, line in ipairs(all_lines) do
    -- stop if a script opening tag is found
    if line:find("{%%") then
      script_start_rel = i
      break
    end
  end

  if script_start_rel == nil then
    return nil
  end

  -- Convert the relative script line number to the line number of the buffer
  local script_start = start_line + script_start_rel - 1

  local script_lines = vim.api.nvim_buf_get_lines(bufnr, script_start, stop_line, false)
  local script_str = ""

  for _, line in ipairs(script_lines) do
    script_str = script_str .. line .. "\n"
    if line:find("%%}") then
      break
    end
  end

  return script_str:match("{%%(.-)%%}")
end

-- is_request_line checks if the given line is a http request line according to RFC 2616
local function is_request_line(line)
  local http_methods = { "GET", "POST", "PUT", "PATCH", "DELETE" }
  for _, method in ipairs(http_methods) do
    if line:find("^" .. method) then
      return true
    end
  end
  return false
end

-- get_headers retrieves all the found headers and returns a lua table with them
-- @param bufnr Buffer number, a.k.a id
-- @param start_line Line where the request starts
-- @param end_line Line where the request ends
local function get_headers(bufnr, start_line, end_line)
  local headers = {}
  local headers_end = end_line

  -- Iterate over all buffer lines starting after the request line
  for line_number = start_line + 1, end_line do
    local line_content = vim.fn.getbufline(bufnr, line_number)[1]

    -- message header and message body are separated by CRLF (see RFC 2616)
    -- for our purpose also the next request line will stop the header search
    if is_request_line(line_content) or line_content == "" then
      headers_end = line_number
      break
    end
    if not line_content:find(":") then
      log.warn("Missing Key/Value pair in message header. Ignoring line: ", line_content)
      goto continue
    end

    local header_name, header_value = line_content:match("^(.-): ?(.*)$")

    if not utils.contains_comments(header_name) then
      headers[header_name] = header_value
    end
    ::continue::
  end

  return headers, headers_end
end

-- get_curl_args finds command line flags and returns a lua table with them
-- @param bufnr Buffer number, a.k.a id
-- @param headers_end Line where the headers end
-- @param end_line Line where the request ends
local function get_curl_args(bufnr, headers_end, end_line)
  local curl_args = {}
  local body_start = end_line

  log.debug("Getting curl args between lines", headers_end, " and ", end_line)
  for line_number = headers_end, end_line do
    local line_content = vim.fn.getbufline(bufnr, line_number)[1]

    if line_content:find("^ *%-%-?[a-zA-Z%-]+") then
      local lc = vim.split(line_content, " ")
      local x = ""

      for i, y in ipairs(lc) do
        x = x .. y

        if #y:match("\\*$") % 2 == 1 and i ~= #lc then
          -- insert space if there is an slash at end
          x = x .. " "
        else
          -- insert 'x' into curl_args and reset it
          table.insert(curl_args, x)
          x = ""
        end
      end
    elseif not line_content:find("^ *$") then
      if line_number ~= end_line then
        body_start = line_number - 1
      end
      break
    end
  end

  return curl_args, body_start
end

-- start_request will find the request line (e.g. POST http://localhost:8081/foo)
-- of the current request and returns the linenumber of this request line.
-- The current request is defined as the next request line above the cursor
-- @param bufnr The buffer number of the .http-file
-- @param linenumber (number) From which line to start looking
local function start_request(bufnr, linenumber)
  log.debug("Searching pattern starting from " .. linenumber)

  local oldlinenumber = linenumber
  utils.move_cursor(bufnr, linenumber)

  local res = vim.fn.search("^GET\\|^POST\\|^PUT\\|^PATCH\\|^DELETE", "bcnW")
  -- restore cursor position
  utils.move_cursor(bufnr, oldlinenumber)

  return res
end

-- end_request will find the next request line (e.g. POST http://localhost:8081/foo)
-- and returns the linenumber before this request line or the end of the buffer
-- @param bufnr The buffer number of the .http-file
local function end_request(bufnr, linenumber)
  -- store old cursor position
  local oldlinenumber = linenumber
  local last_line = vim.fn.line("$")

  -- start searching for next request from the next line
  -- as the current line does contain the current, not the next request
  if linenumber < last_line then
    linenumber = linenumber + 1
  end
  utils.move_cursor(bufnr, linenumber)

  local next = vim.fn.search("^GET\\|^POST\\|^PUT\\|^PATCH\\|^DELETE\\|^###\\", "cnW")

  -- restore cursor position
  utils.move_cursor(bufnr, oldlinenumber)

  if next == 0 or (oldlinenumber == last_line) then
    return last_line
  else
    -- skip comment lines above requests
    while vim.fn.getline(next - 1):find("^ *#") do
      next = next - 1
    end

    return next - 1
  end
end

-- parse_url returns a table with the method of the request and the URL
-- @param stmt the request statement, e.g., POST http://localhost:3000/foo
local function parse_url(stmt)
  -- remove HTTP
  local parsed = utils.split(stmt, " HTTP/")
  local http_version = nil
  if parsed[2] ~= nil then
    http_version = parsed[2]
  end
  parsed = utils.split(parsed[1], " ")
  local http_method = parsed[1]
  table.remove(parsed, 1)
  local target_url = table.concat(parsed, " ")

  target_url = utils.replace_vars(target_url)
  if config.get("encode_url") then
    -- Encode URL
    target_url = utils.encode_url(target_url)
  end

  return {
    method = http_method,
    http_version = http_version,
    url = target_url,
  }
end

local M = {}
M.get_current_request = function()
  return M.buf_get_request(vim.api.nvim_win_get_buf(0), vim.fn.getcurpos())
end

-- buf_get_request returns a table with all the request settings
-- @param bufnr (number|nil) the buffer number
-- @param curpos the cursor position
-- @return (boolean, request or string)
M.buf_get_request = function(bufnr, curpos)
  curpos = curpos or vim.fn.getcurpos()
  bufnr = bufnr or vim.api.nvim_win_get_buf(0)

  local start_line = start_request(bufnr, curpos[2])

  if start_line == 0 then
    return false, "No request found"
  end
  local end_line = end_request(bufnr, start_line)

  local parsed_url = parse_url(vim.fn.getline(start_line))

  local headers, headers_end = get_headers(bufnr, start_line, end_line)

  local curl_args, body_start = get_curl_args(bufnr, headers_end, end_line)

  local host = headers[utils.key(headers,"host")] or ""
  parsed_url.url = host:gsub("%s+", "") .. parsed_url.url
  headers[utils.key(headers,"host")] = nil

  local body = get_body(bufnr, body_start, end_line)

  local script_str = get_response_script(bufnr, headers_end, end_line)

  -- TODO this should just parse the request without modifying external state
  -- eg move to run_request
  if config.get("jump_to_request") then
    utils.move_cursor(bufnr, start_line)
  else
    utils.move_cursor(bufnr, curpos[2], curpos[3])
  end

  local req = {
      method = parsed_url.method,
      url = parsed_url.url,
      http_version = parsed_url.http_version,
      headers = headers,
      raw = curl_args,
      body = body,
      bufnr = bufnr,
      start_line = start_line,
      end_line = end_line,
      script_str = script_str,
    }

  return true, req
end

M.print_request = function(req)
  print(M.stringify_request(req))
end

-- converts request into string, helpful for debug
-- full_body boolean
M.stringify_request = function(req, opts)
  opts = vim.tbl_deep_extend(
    "force", -- use value from rightmost map
    { full_body = false, headers = true }, -- defaults
    opts or {}
  )
  local str = [[
    url   : ]] .. req.url .. [[\n
    method: ]] .. req.method .. [[\n
    range : ]] .. tostring(req.start_line) .. [[ -> ]] .. tostring(req.end_line) .. [[\n
    ]]

  if req.http_version then
    str = str .. "\nhttp_version: " .. req.http_version .. "\n"
  end

  if opts.headers then
    for name, value in pairs(req.headers) do
      str = str .. "header '" .. name .. "'=" .. value .. "\n"
    end
  end

  if opts.full_body then
    if req.body then
      local res = req.body
      str = str .. "body: " .. res .. "\n"
    end
  end

  -- here we should just display the beginning of the request
  return str
end

M.buf_list_requests = function(buf, _opts)
  local last_line = vim.fn.line("$")
  local requests = {}

  -- reset cursor position
  vim.fn.cursor({ 1, 1 })
  local curpos = vim.fn.getcurpos()
  log.debug("Listing requests for buf ", buf)
  while curpos[2] <= last_line do
    local ok, req = M.buf_get_request(buf, curpos)
    if ok then
      curpos[2] = req.end_line + 1
      requests[#requests + 1] = req
    else
      break
    end
  end
  -- log.debug("found " , #requests , "requests")
  return requests
end

local select_ns = vim.api.nvim_create_namespace("rest-nvim")
M.highlight = function(bufnr, start_line, end_line)
  local opts = config.get("highlight") or {}
  local higroup = "IncSearch"
  local timeout = opts.timeout or 150

  vim.api.nvim_buf_clear_namespace(bufnr, select_ns, 0, -1)

  local end_column = string.len(vim.fn.getline(end_line))

  vim.highlight.range(
    bufnr,
    select_ns,
    higroup,
    { start_line - 1, 0 },
    { end_line - 1, end_column },
    { regtype = "c"; inclusive = false }
  )

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, select_ns, 0, -1)
    end
  end, timeout)
end

return M
