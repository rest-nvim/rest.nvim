local utils = require("rest-nvim.utils")
local path = require("plenary.path")
local log = require("plenary.log").new({ plugin = "rest.nvim", level = "debug" })
local config = require("rest-nvim.config")

-- get_importfile returns in case of an imported file the absolute filename
-- @param bufnr Buffer number, a.k.a id
-- @param stop_line Line to stop searching
local function get_importfile_name(bufnr, start_line, stop_line)
  -- store old cursor position
  local oldpos = vim.fn.getcurpos()
  utils.move_cursor(bufnr, start_line)

  local import_line = vim.fn.search("^<", "n", stop_line)
  -- restore old cursor position
  utils.move_cursor(bufnr, oldpos[2])

  if import_line > 0 then
    local fileimport_string
    local fileimport_line
    fileimport_line = vim.api.nvim_buf_get_lines(bufnr, import_line - 1, import_line, false)
    fileimport_string = string.gsub(fileimport_line[1], "<", "", 1)
      :gsub("^%s+", "")
      :gsub("%s+$", "")
    -- local fileimport_path = path:new(fileimport_string)
    -- if fileimport_path:is_absolute() then
    if path:new(fileimport_string):is_absolute() then
      return fileimport_string
    else
      local file_dirname = vim.fn.expand("%:p:h")
      local file_name = path:new(path:new(file_dirname), fileimport_string)
      return file_name:absolute()
    end
  end
  return nil
end

-- get_body retrieves the body lines in the buffer and then returns
-- either a raw string with the body if it is JSON, or a filename. Plenary.curl can distinguish
-- between strings with filenames and strings with the raw body
-- @param bufnr Buffer number, a.k.a id
-- @param start_line Line where body starts
-- @param stop_line Line where body stops
local function get_body(bufnr, start_line, stop_line)
  if start_line >= stop_line then
    return
  end

  -- first check if the body should be imported from an external file
  local importfile = get_importfile_name(bufnr, start_line, stop_line)
  local lines
  if importfile ~= nil then
    if not utils.file_exists(importfile) then
      error("import file " .. importfile .. " not found")
    end
    lines = utils.read_file(importfile)
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, start_line, stop_line, false)
  end

  local body = ""
  -- nvim_buf_get_lines is zero based and end-exclusive
  -- but start_line and stop_line are one-based and inclusive
  -- magically, this fits :-) start_line is the CRLF between header and body
  -- which should not be included in the body, stop_line is the last line of the body
  for _, line in ipairs(lines) do
    -- Ignore commented lines with and without indent
    if not utils.contains_comments(line) then
      body = body .. utils.replace_vars(line)
    end
  end

  return body
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
  local body_start = end_line

  -- Iterate over all buffer lines starting after the request line
  for line_number = start_line + 1, end_line do
    local line = vim.fn.getbufline(bufnr, line_number)
    local line_content = line[1]

    -- message header and message body are seperated by CRLF (see RFC 2616)
    -- for our purpose also the next request line will stop the header search
    if is_request_line(line_content) or line_content == "" then
      body_start = line_number
      break
    end
    if not line_content:find(":") then
      log.warn("Missing Key/Value pair in message header. Ignoring line: ", line_content)
      goto continue
    end

    local header = utils.split(line_content, ":")
    local header_name = header[1]:lower()
    table.remove(header, 1)
    local header_value = table.concat(header, ":")
    if not utils.contains_comments(header_name) then
      headers[header_name] = utils.replace_vars(header_value)
    end
    ::continue::
  end

  return headers, body_start
end

-- start_request will find the request line (e.g. POST http://localhost:8081/foo)
-- of the current request and returns the linenumber of this request line.
-- The current request is defined as the next request line above the cursor
-- @param bufnr The buffer nummer of the .http-file
local function start_request()
  return vim.fn.search("^GET\\|^POST\\|^PUT\\|^PATCH\\|^DELETE", "cbn", 1)
end

-- checks if request has variables
local function request_var(url_line)
  return vim.fn.search("^#@", 'cbn', url_line - 1)
end

-- end_request will find the next request line (e.g. POST http://localhost:8081/foo)
-- and returns the linenumber before this request line or the end of the buffer
-- @param bufnr The buffer nummer of the .http-file
local function end_request(bufnr)
  -- store old cursor position
  local curpos = vim.fn.getcurpos()
  local linenumber = curpos[2]
  local oldlinenumber = linenumber

  -- start searching for next request from the next line
  -- as the current line does contain the current, not the next request
  if linenumber < vim.fn.line("$") then
    linenumber = linenumber + 1
  end
  utils.move_cursor(bufnr, linenumber)

  local next = vim.fn.search("^GET\\|^POST\\|^PUT\\|^PATCH\\|^DELETE", "cn", vim.fn.line("$"))

  -- restore cursor position
  utils.move_cursor(bufnr, oldlinenumber)
  local last_line = vim.fn.line("$")

  if next == 0 or (oldlinenumber == last_line) then
    return last_line
  else
    return next - 1
  end
end

-- parse_url returns a table with the method of the request and the URL
-- @param stmt the request statement, e.g., POST http://localhost:3000/foo
local function parse_url(stmt)
  local parsed = utils.split(stmt, " ")
  local http_method = parsed[1]
  table.remove(parsed, 1)
  local target_url = table.concat(parsed, " ")

  return {
    method = http_method,
    -- Encode URL
    url = utils.encode_url(utils.replace_vars(target_url)),
  }
end

local function parse_req_var(stmt)
  local parsed = stmt:sub(3)
  return parsed
end

local M = {}
M.get_current_request = function()
  local curpos = vim.fn.getcurpos()
  local bufnr = vim.api.nvim_win_get_buf(0)

  local start_line = start_request()
  if start_line == 0 then
    error("No request found")
  end
  local end_line = end_request(bufnr)

  local parsed_url = parse_url(vim.fn.getline(start_line))

  local req_var_line = request_var(start_line)
  local parsed_req_var_str = ''
  if req_var_line ~= 0 then
    parsed_req_var_str = parse_req_var(vim.fn.getline(req_var_line))
  end

  local headers, body_start = get_headers(bufnr, start_line, end_line)

  local body = get_body(bufnr, body_start, end_line)

  if config.get("jump_to_request") then
    utils.move_cursor(bufnr, start_line)
  else
    utils.move_cursor(bufnr, curpos[2], curpos[3])
  end

  return {
    method = parsed_url.method,
    url = parsed_url.url,
    headers = headers,
    body = body,
    bufnr = bufnr,
    start_line = start_line,
    end_line = end_line,
    req_var = parsed_req_var_str,
  }
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
    "c",
    false
  )

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, select_ns, 0, -1)
    end
  end, timeout)
end

return M
