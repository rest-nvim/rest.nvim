local rest = {}

local curl = require("plenary.curl")
local path = require("plenary.path")
local utils = require("rest-nvim.utils")
local log = require("plenary.log").new({ plugin = "rest.nvim", level = "warn" })

local config = {}

local LastOpts = {}

-- setup is needed for enabling syntax highlighting for http files
rest.setup = function(user_configs)
  config = require("rest-nvim.config").set(user_configs or {})
  if vim.fn.expand("%:e") == "http" then
    vim.api.nvim_buf_set_option("%", "filetype", "http")
  end
end

-- get_or_create_buf checks if there is already a buffer with the rest run results
-- and if the buffer does not exists, then create a new one
local function get_or_create_buf()
  local tmp_name = "rest_nvim_results"

  -- Check if the file is already loaded in the buffer
  local existing_bufnr = vim.fn.bufnr(tmp_name)
  if existing_bufnr ~= -1 then
    -- Set modifiable
    vim.api.nvim_buf_set_option(existing_bufnr, "modifiable", true)
    -- Prevent modified flag
    vim.api.nvim_buf_set_option(existing_bufnr, "buftype", "nofile")
    -- Delete buffer content
    vim.api.nvim_buf_set_lines(
      existing_bufnr,
      0,
      vim.api.nvim_buf_line_count(existing_bufnr) - 1,
      false,
      {}
    )

    -- Make sure the filetype of the buffer is httpResult so it will be highlighted
    vim.api.nvim_buf_set_option(existing_bufnr, "ft", "httpResult")

    return existing_bufnr
  end

  -- Create new buffer
  local new_bufnr = vim.api.nvim_create_buf(false, "nomodeline")
  vim.api.nvim_buf_set_name(new_bufnr, tmp_name)
  vim.api.nvim_buf_set_option(new_bufnr, "ft", "httpResult")
  vim.api.nvim_buf_set_option(new_bufnr, "buftype", "nofile")

  return new_bufnr
end

-- parse_url returns a table with the method of the request and the URL
-- @param stmt the request statement, e.g., POST http://localhost:3000/foo
local function parse_url(stmt)
  local parsed = utils.split(stmt, " ")
  return {
    method = parsed[1],
    -- Encode URL
    url = utils.encode_url(utils.replace_vars(parsed[2])),
  }
end

-- go_to_line moves the cursor to the desired line in the provided buffer
-- @param bufnr Buffer number, a.k.a id
-- @param line the desired cursor position
local function go_to_line(bufnr, line)
  vim.api.nvim_buf_call(bufnr, function()
    vim.fn.cursor(line, 1)
  end)
end

-- get_importfile returns in case of an imported file the absolute filename
-- @param bufnr Buffer number, a.k.a id
-- @param stop_line Line to stop searching
local function get_importfile(bufnr, start_line, stop_line)
  -- store old cursor position
  local oldpos = vim.fn.getcurpos()
  go_to_line(bufnr, start_line)

  local import_line = vim.fn.search("^<", "n", stop_line)
  -- restore old cursor position
  go_to_line(bufnr, oldpos[2])

  if import_line > 0 then
    local fileimport_string
    local fileimport_line
    fileimport_line = vim.api.nvim_buf_get_lines(bufnr, import_line - 1, import_line, false)
    fileimport_string = fileimport_line[1]
    fileimport_string = string.gsub(fileimport_string, "<", "", 1):gsub("^%s+", ""):gsub("%s+$", "")
    local fileimport_path = path.new(fileimport_string)
    if not fileimport_path:is_absolute() then
      local buffer_name = vim.api.nvim_buf_get_name(bufnr)
      local buffer_path = path.new(path.new(buffer_name):parent())
      fileimport_path = buffer_path:joinpath(fileimport_path)
    end
    return fileimport_path:absolute()
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
  local importfile = get_importfile(bufnr, start_line, stop_line)
  if importfile ~= nil then
    return importfile
  end

  local lines
  local body = ""
  -- nvim_buf_get_lines is zero based and end-exclusive
  -- but start_line and stop_line are one-based and inclusive
  -- magically, this fits :-) start_line is the CRLF between header and body
  -- which should not be included in the body, stop_line is the last line of the body
  lines = vim.api.nvim_buf_get_lines(bufnr, start_line, stop_line, false)
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
-- @param query_line Line to set cursor position
local function get_headers(bufnr, query_line)
  local headers = {}
  -- Set stop at end of buffer
  local stop_line = vim.fn.line("$")
  local body_start = 0

  -- Iterate over all buffer lines
  for line_number = query_line + 1, stop_line do
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
    if not utils.contains_comments(header[1]) then
      headers[header[1]:lower()] = utils.replace_vars(header[2])
    end
    ::continue::
  end

  return headers, body_start
end

-- curl_cmd runs curl with the passed options, gets or creates a new buffer
-- and then the results are printed to the recently obtained/created buffer
-- @param opts curl arguments
local function curl_cmd(opts)
  LastOpts = opts
  local res = curl[opts.method](opts)
  if opts.dry_run then
    print("[rest.nvim] Request preview:\n" .. "curl " .. table.concat(res, " "))
    return
  end

  if res.exit ~= 0 then
    error("[rest.nvim] " .. utils.curl_error(res.exit))
  end

  local res_bufnr = get_or_create_buf()
  local parsed_url
  if opts.run_last then
    parsed_url = {
      method = opts.method,
      url = opts.url,
    }
  else
    parsed_url = parse_url(vim.fn.getline("."))
  end
  local json_body = false

  -- Check if the content-type is "application/json" so we can format the JSON
  -- output later
  for _, header in ipairs(res.headers) do
    if string.find(header, "application/json") then
      json_body = true
      break
    end
  end

  --- Add metadata into the created buffer (status code, date, etc)
  -- Request statement (METHOD URL)
  vim.api.nvim_buf_set_lines(res_bufnr, 0, 0, false, { parsed_url.method .. " " .. parsed_url.url })
  -- HTTP version, status code and its meaning, e.g. HTTP/1.1 200 OK
  local line_count = vim.api.nvim_buf_line_count(res_bufnr)
  vim.api.nvim_buf_set_lines(
    res_bufnr,
    line_count,
    line_count,
    false,
    { "HTTP/1.1 " .. utils.http_status(res.status) }
  )
  -- Headers, e.g. Content-Type: application/json
  vim.api.nvim_buf_set_lines(
    res_bufnr,
    line_count + 1,
    line_count + 1 + #res.headers,
    false,
    res.headers
  )

  --- Add the curl command results into the created buffer
  if json_body then
    -- format JSON body
    res.body = vim.fn.system("jq", res.body)
  end
  local lines = utils.split(res.body, "\n")
  line_count = vim.api.nvim_buf_line_count(res_bufnr) - 1
  vim.api.nvim_buf_set_lines(res_bufnr, line_count, line_count + #lines, false, lines)

  -- Only open a new split if the buffer is not loaded into the current window
  if vim.fn.bufwinnr(res_bufnr) == -1 then
    local cmd_split = [[vert sb]]
    if config.result_split_horizontal == true then
      cmd_split = [[sb]]
    end
    vim.cmd(cmd_split .. res_bufnr)
    -- Set unmodifiable state
    vim.api.nvim_buf_set_option(res_bufnr, "modifiable", false)
  end

  -- Send cursor in response buffer to start
  go_to_line(res_bufnr, 1)
end

-- start_request will find the request line (e.g. POST http://localhost:8081/foo)
-- of the current request and returns the linenumber of this request line.
-- The current request is defined as the next request line above the cursor
-- @param bufnr The buffer nummer of the .http-file
local function start_request()
  return vim.fn.search("^GET\\|^POST\\|^PUT\\|^PATCH\\|^DELETE", "cbn", 1)
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
  go_to_line(bufnr, linenumber)

  local next = vim.fn.search("^GET\\|^POST\\|^PUT\\|^PATCH\\|^DELETE", "cn", vim.fn.line("$"))

  -- restore cursor position
  go_to_line(bufnr, oldlinenumber)
  return next > 1 and next - 1 or vim.fn.line("$")
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
-- @param verbose toggles if only a dry run with preview should be executed (true = preview)
rest.run = function(verbose)
  local bufnr = vim.api.nvim_win_get_buf(0)

  local start_line = start_request()
  if start_line == 0 then
    error("[rest.nvim]: No request found")
    return
  end
  local end_line = end_request()
  go_to_line(bufnr, start_line)

  local parsed_url = parse_url(vim.fn.getline(start_line))

  local headers, body_start = get_headers(bufnr, start_line)

  local body = get_body(bufnr, body_start, end_line)

  local success_req, req_err = pcall(curl_cmd, {
    method = parsed_url.method:lower(),
    url = parsed_url.url,
    headers = headers,
    -- accept = accept,
    body = body, -- the request body (string/filepath/table)
    dry_run = verbose and verbose or false,
  })

  if not success_req then
    vim.api.nvim_err_writeln(
      "[rest.nvim] Failed to perform the request.\nMake sure that you have entered the proper URL and the server is running.\n\nTraceback: "
        .. req_err
    )
  end
end

rest.last = function()
  if LastOpts.url == nil then
    error("[rest.nvim]: Last request not found")
  end
  LastOpts.run_last = true
  local success_req, req_err = pcall(curl_cmd, LastOpts)

  if not success_req then
    vim.api.nvim_err_writeln(
      "[rest.nvim] Failed to perform the request.\nMake sure that you have entered the proper URL and the server is running.\n\nTraceback: "
        .. req_err
    )
  end
end

return rest
