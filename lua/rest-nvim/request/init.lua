local utils = require("rest-nvim.utils")
local path = require("plenary.path")
local log = require("plenary.log").new({ plugin = "rest.nvim" })
local config = require("rest-nvim.config")

local ts = vim.treesitter
local ts_utils = require 'nvim-treesitter.ts_utils'

local parser_name = "http"

local M = {}

-- todo add a metatable with stringify etc
-- local Request = {}


-- | validate dict is conform to what is expected in an array
-- in absence of types, that's what we can do best
M.validate_request = function(request)

  return vim.validate({ user_configs = { request, "table" } })
  -- check keys/values ?

  -- return {
  --     method = parsed_url.method,
  --     url = parsed_url.url,
  --     http_version = parsed_url.http_version,
  --     headers = headers,
  --     raw = curl_args,
  --     body = body,
  --     bufnr = bufnr,
  --     start_line = start_line,
  --     end_line = end_line,
  --     script_str = script_str
  --   }
end

-- get_importfile returns in case of an imported file the absolute filename
-- @param bufnr Buffer number, a.k.a id
-- @param stop_line Line to stop searching
-- TODO load it via grammar !
-- return complete filename
local function load_importfile_name(_bufnr, rawfilename, vars)
  log.debug("Loading importfile " .. rawfilename)

    local fileimport_spliced
  fileimport_spliced = utils.replace_vars(rawfilename, vars)
    if path:new(fileimport_spliced):is_absolute() then
      return fileimport_spliced
    else
      local file_dirname = vim.fn.expand("%:p:h")
      local file_name = path:new(path:new(file_dirname), fileimport_spliced)
      return file_name:absolute()
    end
end

-- print("GETTING BODY FROM ", start_line, " to ", stop_line)
-- -- first check if the body should be imported from an external file
-- local importfile = get_importfile_name(bufnr, start_line, stop_line)

-- get_body retrieves the body lines in the buffer and then returns
-- either a table if the body is a JSON or a raw string if it is a filename
-- Plenary.curl allows a table or a raw string as body and can distinguish
-- between strings with filenames and strings with the raw body
-- @param bufnr Buffer number, a.k.a id
-- @param vars Session variables
-- @param start_line Line where body starts
-- @param stop_line Line where body stops
-- @param has_json True if content-type is set to json
-- luacheck: ignore unused-local unused-function
local function get_body(bufnr, vars, start_line, stop_line, has_json)

  print("GETTING BODY FROM ", start_line, " to ", stop_line)
  -- first check if the body should be imported from an external file
  local importfile = get_importfile_name(bufnr, start_line, stop_line)
  local lines
  if importfile ~= nil then
    if not utils.file_exists(importfile) then
      error("import file " .. importfile .. " not found")
    end
    lines = utils.read_file(importfile)
  else
    lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, stop_line, false)
  end

  local body = ""
  -- nvim_buf_get_lines is zero based and end-exclusive
  -- but start_line and stop_line are one-based and inclusive
  -- magically, this fits :-) start_line is the CRLF between header and body
  -- which should not be included in the body, stop_line is the last line of the body
  for _, line in ipairs(lines) do
    -- stop if a script opening tag is found
    if line:find("{%%") then
      break
    end
    -- Ignore commented lines with and without indent
    if not utils.contains_comments(line) then
      body = body .. utils.replace_vars(line, vars)
    end
  end

  local is_json, json_body = pcall(vim.json.decode, body)

  if is_json then
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

  return body
end

-- get_curl_args finds command line flags and returns a lua table with them
-- @param bufnr Buffer number, a.k.a id
-- @param headers_end Line where the headers end
-- @param end_line Line where the request ends
-- local function get_curl_args(bufnr, headers_end, end_line)
--   local curl_args = {}
--   local body_start = end_line

--   for line_number = headers_end, end_line do
--     local line_content = vim.fn.getbufline(bufnr, line_number)[1]

--     if line_content:find("^ *%-%-?[a-zA-Z%-]+") then
--       local lc = vim.split(line_content, " ")
--       local x = ""

--       for i, y in ipairs(lc) do
--         x = x .. y

--         if #y:match("\\*$") % 2 == 1 and i ~= #lc then
--           -- insert space if there is an slash at end
--           x = x .. " "
--         else
--           -- insert 'x' into curl_args and reset it
--           table.insert(curl_args, x)
--           x = ""
--         end
--       end
--     elseif not line_content:find("^ *$") then
--       if line_number ~= end_line then
--         body_start = line_number - 1
--       end
--       break
--     end
--   end

--   return curl_args, body_start
-- end

-- start_request will find the request line (e.g. POST http://localhost:8081/foo)
-- of the current request and returns the linenumber of this request line.
-- The current request is defined as the next request line above the cursor
-- @param bufnr The buffer nummer of the .http-file
-- @param linenumber (number) From which line to start looking
local function start_request(bufnr, linenumber)
  log.debug("Searching pattern starting from " .. linenumber)

  local oldlinenumber = linenumber
  utils.move_cursor(bufnr, linenumber)

  local res = vim.fn.search("^GET\\|^POST\\|^PUT\\|^PATCH\\|^DELETE", "cn")
  -- restore cursor position
  utils.move_cursor(bufnr, oldlinenumber)

  return res
end

-- end_request will find the next request line (e.g. POST http://localhost:8081/foo)
-- and returns the linenumber before this request line or the end of the buffer
-- @param bufnr The buffer nummer of the .http-file
local function end_request(bufnr, linenumber)
  -- store old cursor position
  local oldlinenumber = linenumber

  -- start searching for next request from the next line
  -- as the current line does contain the current, not the next request
  if linenumber < vim.fn.line("$") then
    linenumber = linenumber + 1
  end
  utils.move_cursor(bufnr, linenumber)

  local next = vim.fn.search("^GET\\|^POST\\|^PUT\\|^PATCH\\|^DELETE\\|^###\\", "cn",
    vim.fn.line("$"))

  -- restore cursor position
  utils.move_cursor(bufnr, oldlinenumber)
  local last_line = vim.fn.line("$")

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
-- @param vars session variables
local function parse_url(stmt, vars)
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

  target_url = utils.replace_vars(target_url, vars)
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


local function print_node(title, node)
  print(string.format("%s: type '%s' isNamed '%s' with %d children", title, node:type(), node:named()
    , node:child_count()))
end

-- return the lua script code if any
-- ideally we could have several
local function ts_load_script(qnode)
  log.debug("Loading script")
  -- TODO
  -- load_raw
  print("Looking for script")
  for node, name in qnode:iter_children() do
    -- print("type", node:type(), "NAME: ", name)

    -- wont work, it needs to be "script"
    if node:type() == "script" then
      -- print("type", node:type(), "NAME: ", node:named())
      return node

      -- node:field("internal_script")
      -- local internal_script = node:child(0)
      -- -- TODO there are lots of errors which breaks the stuff
      -- print("number of children ", node:child_count())
      -- print("Internal ?", vim.inspect(internal_script))
      -- print("Internal ?", internal_script)
      -- print_node("found internal script: ", internal_script)
      -- return internal_script
    end
  end
end


--
local function encode_json(body, json_ctype)
  local is_json, json_body = pcall(vim.json.decode, body)

  if is_json then
    -- print("it is json")
    if json_ctype then
      print("and we have a json ctype !")
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

local function ts_get_body(bufnr, qnode, vars, _has_json)
  local lines
  -- local body_node
  -- iter direct children
  log.debug("Looking for body")
  for node, _name in qnode:iter_children(qnode) do
    -- print("type", node:type(), "NAME: ", name)
    if node:type() == "body" then
      -- there should be only one child ?
      local body = node:child(0)
      local payload_file_fields = body:field("payload_file")
      -- print("number of children ", body:type())
      -- print("number of fields payload_file ", vim.inspect(body:field("payload_file")))
      if #payload_file_fields > 0 then
        local payload_file_node = payload_file_fields[1]
        print_node("payload file node ?", payload_file_node)
        -- print_node("found payload node: ", node)
        -- replace the filename with variables than load the file
        local raw_filename = vim.treesitter.query.get_node_text(payload_file_node, bufnr)
        -- local final_filename = utils.replace_vars(raw_filename, vars)
        -- TODO move code ?
        local importfile = load_importfile_name(bufnr, raw_filename, vars)
        if importfile ~= nil then
          if not utils.file_exists(importfile) then
            error("import file " .. importfile .. " not found")
          end
          lines = utils.read_file(importfile)
          -- print("LINES", lines)
          local res = encode_json(table.concat(lines, "\n"),_has_json)
          return res
          -- return lines
        end
      end

    end
  end
end

-- Build a rest.nvim request from a treesitter query
-- @param node a treeitter node of type "query" TODO assert/check
-- @param bufnr
M.ts_build_request_from_node = function(reqnode, bufnr)
  assert(reqnode:type() == "query")

  -- log.debug('building request_from_node')
  local vars = utils.read_variables()

  -- named_child(0)
  -- local reqnode = tsnode:child(0)
  -- local id = "toto"
  print_node("reqnode", reqnode)

  -- Returns a table of the nodes corresponding to the {name} field.
  local methodfields = reqnode:field("request")
  local methodnode = methodfields[1]:field("method")[1]
  local urlnode = methodfields[1]:field('url')[1]
  print("url content ?", vim.treesitter.query.get_node_text(urlnode, bufnr))
  local url = vim.treesitter.query.get_node_text(urlnode, bufnr)
  url = utils.replace_vars(url, vars)

  -- TODO splice header variables/pass variables
  local headers = M.ts_get_headers(reqnode, bufnr)
  local headers_spliced = {}
  for name, value in pairs(headers) do
    headers_spliced[name] = utils.replace_vars(value, vars)
  end

  -- if not utils.contains_comments(header_name) then
  --   headers[header_name] = utils.replace_vars(header_value)
  -- end

  -- HACK !!!
  -- Because we have trouble catching the body through tree-sitter
  -- we just look set the end_line to the (beginning -1) line of the next request
  -- or the last line if there are no other requests
  local end_line = vim.fn.line("$")

  -- TODO look for next_sibling of same type query
  local nextreq = reqnode:next_sibling()
  while nextreq and nextreq:type() ~= "query" do
    nextreq = nextreq:next_sibling()
  end

  -- print_node("reqnode ", reqnode)
  -- print_node("next query", nextreq)
  if nextreq then
    -- print("Found another sibling", nextreq:id())
    -- print_node("final nextreq", nextreq)
    end_line = nextreq:start() - 1
  else
    print("found no other sibling")
  end

  --
  -- local curl_args, body_start = get_curl_args(bufnr, headers_end, end_line)
  local script_str
  local script_node = ts_load_script(reqnode)
  if script_node then
    script_str = vim.treesitter.query.get_node_text(script_node, bufnr)

    -- THIS IS A HACK until I can retrieve internal_script properly !
    script_str = script_str:match("{%%(.-)%%}")
    print("using SCRIPT_STR:", script_str)

    log.debug("Using script_str", script_str)
  end

  -- sounds like a bug, it should be + 1 ?
  -- local headers_end = reqnode:end_() + 2

  -- TODO wip
  local body = ts_get_body(
    bufnr,
    reqnode,
    vars,
    -- TODO assume json for now but we should look at headers ctype
    true
  )

  -- load the body
  -- if script_node then
  --   script_str = vim.treesitter.query.get_node_text(script_node, bufnr)
  -- end

  -- local body = get_body(
  --   bufnr,
  --   vars,
  --   headers_end,
  --   end_line,
  --   true -- assume json for now
  --   -- content_type:find("application/[^ ]*json")
  -- )

  print("RETURNED BODY", body)

  -- local script_str = get_response_script(bufnr,headers_end, end_line)

  return {
    method = vim.treesitter.query.get_node_text(methodnode, bufnr),
    url = url,
    -- TODO found from parse_url but should use ts as well:
    -- methodnode:field('http_version')[1],
    http_version = nil,
    headers = headers_spliced,
    -- TODO build curl_args from 'headers'
    -- I dont really care about that so I left it
    raw = nil,
    -- TODO check if body is full string ?
    body = body,
    bufnr = bufnr,
    start_line = reqnode:start(),
    -- le end line is computed
    end_line = end_line,
    -- todo
    script_str = script_str

  }
end

-- TODO we should return headers for query
M.ts_get_headers = function(qnode, bufnr)
  -- local parser = ts.get_parser(bufnr, "http")
  -- print("PARSER", parser)
  local query = [[
      (header) @headers
  ]]

  local parsed_query = ts.parse_query(parser_name, query)
  -- print(vim.inspect(parsed_query))
  -- local start_row, _, end_row, _ = qnode:range()
  -- print("start row", start_row, "end row", end_row)

  local headers = {}
  for _id, headernode, _metadata in parsed_query:iter_captures(qnode, bufnr) do
    -- local name = parsed_query.captures[id] -- name of the capture in the query
    -- M.ts_build_request_from_node(tsnode, bufnr)
    -- print_node("header node", headernode)
    -- Returns a table of the nodes corresponding to the {name} field.

    local hnamenode = headernode:field("name")[1]
    local hname = vim.treesitter.query.get_node_text(hnamenode, bufnr)
    local valuenode = headernode:field("value")[1]
    local value = vim.treesitter.query.get_node_text(valuenode, bufnr)
    -- TODO splice value variables !
    headers[hname] = value
  end
  return headers
end

M.buf_get_requests = function(bufnr)
  bufnr = bufnr or 0

  print("GET REQUESTS for buffer ", bufnr)
  -- local parser = ts.get_parser(bufnr, "http")
  -- print("PARSER", parser)
  local query = [[
      (query) @queries
  ]]
  -- parse returns a list of ts trees
  -- root is a node
  -- local root = parser:parse()[1]:root()
  -- local start_row, _, end_row, _ = root:range()

  -- local start_node = root
  local start_node = ts_utils.get_node_at_cursor()
  -- print_node("Node at cursor", start_node)
  -- print("sexpr: " .. start_node:sexpr())
  local parsed_query = ts.parse_query(parser_name, query)
  -- print(vim.inspect(parsed_query))
  -- print("start row", start_row, "end row", end_row)
  -- print_node("root", root)
  local requests = {}
  -- , start_row, end_row
  for _id, tsnode, _metadata in parsed_query:iter_captures(start_node, bufnr) do
    -- local name = parsed_query.captures[id] -- name of the capture in the query

    requests[#requests] = M.ts_build_request_from_node(tsnode, bufnr)
  end

  return requests
end

M.get_current_request = function()
  return M.buf_get_current_request()
end

M.buf_get_current_request = function(bufnr)
  log.debug("Getting current request")

  -- old implementation
  -- return M.buf_get_request(vim.api.nvim_win_get_buf(0), vim.fn.getcurpos())
  local query_node = M.buf_get_request_at_node(bufnr, ts_utils.get_node_at_cursor())
  local result = M.ts_build_request_from_node(query_node, 0)
  M.print_request(result)
  return true, result
end

M.buf_get_request_at_node = function(_bufnr, start_node)
  local parser = ts.get_parser(0, "http")
  local root = parser:parse()[1]:root()
  -- local start_node = ts_utils.get_node_at_cursor()
  -- print("start node type", start_node:type())
  local node = start_node
  while node:type() ~= "query" and node ~= root do
    -- print("node before", node:type())
    node = node:parent()

    -- node = ts_utils.get_previous_node(node, true, true)
    -- print("node after", node:type())
  end
  -- print("out of loop node", node:type())
  return node
end

-- buf_get_request returns a table with all the request settings
-- @param bufnr (number|nil) the buffer number
-- @param pos (optional) the cursor position, by default the cursor position
-- @return (boolean, request or string)
M.buf_get_request_at_pos = function(bufnr, pos)
  pos = pos or vim.fn.getcurpos()
  bufnr = bufnr or vim.api.nvim_win_get_buf(0)
  --
  local node = M.get_node_at_pos(bufnr, pos[1] - 1, pos[2], { ignore_injections = false }):type()
  return M.buf_get_request(bufnr, node)

end

-- to remove
M.print_request = function(req)
  print(M.stringify_request(req))
end

-- converts request into string, helpful for debug
-- full_body boolean
M.stringify_request = function(req, opts)
  opts = vim.tbl_deep_extend(
    "force", -- use value from rightmost map
    { full_body = false, -- TODO pass a function instead
      headers = true
    }, -- defaults
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
    -- str = str.."body: "..req.body.."\n"
    for name, value in pairs(req.headers) do
      str = str .. "header '" .. name .. "'=" .. value .. "\n"
    end
  end

  -- opts.full_body
  if true then
    if req.body then
      local res = req.body
      -- table.concat(res, "\n")
      str = str .. "body: " .. res .. "\n"
    end
  end

  -- here we should just display the beginning of the request
  return (str)
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
