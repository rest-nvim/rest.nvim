---@mod rest-nvim.parser rest.nvim http syntax parsing module
---
---@brief [[
---
--- rest.nvim `.http` syntax parsing module.
--- rest.nvim uses `tree-sitter-http` as a core parser for `.http` syntax
---
---@brief ]]

local parser = {}

local Context = require("rest-nvim.context").Context
local script = require("rest-nvim.script")
local utils   = require("rest-nvim.utils")
local logger   = require("rest-nvim.logger")
local jar = require("rest-nvim.cookie_jar")

---@alias Source integer|string Buffer or string which the `node` is extracted

local NAMED_REQUEST_QUERY = vim.treesitter.query.parse("http", [[
(section
  (request_separator
    value: (_) @name)
  request: (_)) @request
(section
  (comment
    name: (_) @keyword
    value: (_) @name
    (#eq? @keyword "name"))
  request: (_)) @request
]])

---@param node TSNode
---@param field string
---@param source Source
---@return string|nil
local function get_node_field_text(node, field, source)
  local n = node:field(field)[1]
  return n and vim.treesitter.get_node_text(n, source) or nil
end

---@param src string
---@param context rest.Context
---@param encoder? fun(s:string):string
---@return string
---@return integer
local function expand_variables(src, context, encoder)
  return src:gsub("{{(.-)}}", function (name)
    name = vim.trim(name)
    local res = context:resolve(name)
    if encoder then
      res = encoder(res)
    end
    return res
  end)
end

---@param req_node TSNode Tree-sitter request node
---@param source Source
---@param context rest.Context
---@return table<string,string[]> headers
local function parse_headers(req_node, source, context)
  local headers = vim.defaulttable(function () return {} end)
  local header_nodes = req_node:field("header")
  for _, node in ipairs(header_nodes) do
    local key = assert(get_node_field_text(node, "name", source))
    local value = assert(get_node_field_text(node, "value", source))
    key = expand_variables(key, context)
    value = expand_variables(value, context)
    key = string.lower(key)
    table.insert(headers[key], value)
  end
  return setmetatable(headers, nil)
end

---@param body_node TSNode
---@param source Source
---@param context rest.Context
---@return rest.Request.Body|nil
function parser.parse_body(body_node, source, context)
  local body = {}
  body.__TYPE = body_node:type():gsub("_%w+", "")
  ---@cast body rest.Request.Body
  if body.__TYPE == "json" then
    body.data = vim.trim(vim.treesitter.get_node_text(body_node, source))
    body.data = expand_variables(body.data, context)
    local ok, _ = pcall(vim.json.decode, body.data)
    if not ok then
      logger.warn("invalid json: '" .. body.data .. "'")
      return nil
    end
  elseif body.__TYPE == "xml" then
    body.data = vim.trim(vim.treesitter.get_node_text(body_node, source))
    body.data = expand_variables(body.data, context)
    local xml2lua = require("xml2lua")
    local handler = require("xmlhandler.tree"):new()
    local xml_parser = xml2lua.parser(handler)
    local ok = pcall(function (t) return xml_parser:parse(t) end, body.data)
    if not ok then
      logger.warn("invalid xml: '" .. body.data .. "'")
      return nil
    end
  elseif body.__TYPE == "form" then
    body.data = {}
    for pair, _ in body_node:iter_children() do
      if pair:type() == "query" then
        local key = assert(get_node_field_text(pair, "key", source))
        local value = assert(get_node_field_text(pair, "value", source))
        key = expand_variables(key, context)
        value = expand_variables(value, context)
        body.data[key] = value
      end
    end
  elseif body.__TYPE == "external" then
    local path = assert(get_node_field_text(body_node, "path", source))
    path = vim.fs.normalize(vim.fs.joinpath(vim.fn.expand("%:h"), path))
    body.data = {
      name = get_node_field_text(body_node, "name", source),
      path = path,
    }
  elseif body.__TYPE == "graphql" then
    logger.error("graphql body is not supported yet")
  end
  return body
end

local IN_PLACE_VARIABLE_QUERY = "(variable_declaration) @inplace_variable"

---parse all in-place variables from source
---@param source Source
---@return rest.Context ctx
function parser.create_context(source)
  local query = vim.treesitter.query.parse("http", IN_PLACE_VARIABLE_QUERY)
  local ctx = Context:new()
  local _, tree = utils.ts_parse_source(source)
  for _, node in query:iter_captures(tree:root(), source) do
    if node:type() == "variable_declaration" then
      parser.parse_variable_declaration(node, source, ctx)
    end
  end
  return ctx
end

---@return TSNode? node TSNode with type `section`
function parser.get_cursor_request_node()
  local node = vim.treesitter.get_node()
  if node then
    node = utils.ts_find(node, "section")
    if not node or #node:field("request") < 1 then
      return
    end
  end
  return node
end

---@return TSNode[]
function parser.get_all_request_node()
  local source = 0
  local _, tree = utils.ts_parse_source(source)
  local reqs = {}
  for node, _ in tree:root():iter_children() do
    if node:type() == "request" then
      table.insert(reqs, node)
    end
  end
  return reqs
end

---@return TSNode?
function parser.get_request_node_by_name(name)
  local source = 0
  local _, tree = utils.ts_parse_source(source)
  local query = NAMED_REQUEST_QUERY
  for id, node, _metadata, _match in query:iter_captures(tree:root(), source) do
    local capture_name = query.captures[id]
    if capture_name == "name" and vim.treesitter.get_node_text(node, source) == name then
      local find = utils.ts_find(node, "section")
      if find then
        return find
      end
    end
  end
end

---@param vd_node TSNode
---@param source Source
---@param ctx rest.Context
function parser.parse_variable_declaration(vd_node, source, ctx)
  vim.validate({ node = utils.ts_node_spec(vd_node, "variable_declaration") })
  local name = assert(get_node_field_text(vd_node, "name", source))
  local value = vim.trim(assert(get_node_field_text(vd_node, "value", source)))
  value = expand_variables(value, ctx)
  ctx:set(name, value)
end

---@param node TSNode
---@param source Source
---@return string str
local function parse_script(node, source)
  vim.validate({ node = utils.ts_node_spec(node, "script") })
  local str = vim.treesitter.get_node_text(node, source):sub(3,-3)
  return str
end

---@param script_node TSNode
---@param source Source
---@param context rest.Context
function parser.parse_pre_request_script(script_node, source, context)
  local node = assert(script_node:named_child(0))
  local str = parse_script(node, source)
  script.load_prescript(str, context)()
end

---@param handler_node TSNode
---@param source Source
---@param context rest.Context
function parser.parse_request_handler(handler_node, source, context)
  local node = assert(handler_node:named_child(0))
  local str = parse_script(node, source)
  return script.load_handler(str, context)
end

---@param source Source
---@return string[]
function parser.get_request_names(source)
  local _, tree = utils.ts_parse_source(source)
  local query = NAMED_REQUEST_QUERY
  local result = {}
  for id, node, _metadata, _match in query:iter_captures(tree:root(), source) do
    local capture_name = query.captures[id]
    if capture_name == "name" then
      table.insert(result, vim.treesitter.get_node_text(node, source))
    end
  end
  return result
end

---Parse the request node and create Request object. Returns `nil` if parsing
---failed.
---@param node TSNode Tree-sitter request node
---@param source Source
---@param ctx? rest.Context
---@return rest.Request|nil
function parser.parse(node, source, ctx)
  assert(node:type() == "section")
  ctx = ctx or Context:new()
  -- request should not include error
  if node:has_error() then
    logger.error(utils.ts_node_error_log(node))
    return nil
  end
  local req_node = node:field("request")[1]
  if not req_node then
    logger.error("request section doesn't have request node")
    return nil
  end
  local body
  local body_node = req_node:field("body")[1]
  if body_node then
    body = parser.parse_body(body_node, source, ctx)
    if not body then
      logger.error("parsing body failed")
      return nil
    end
  end
  local method = get_node_field_text(req_node, "method", source)
  if not method then
    logger.info("no method provided, falling back to 'GET'")
    method = "GET"
  end
  local url = expand_variables(
    assert(get_node_field_text(req_node, "url", source)),
    ctx,
    utils.escape
  )

  local name
  local handlers = {}
  for child, _ in node:iter_children() do
    local node_type = child:type()
    if node_type == "pre_request_script" then
      parser.parse_pre_request_script(child, source, ctx)
    elseif node_type == "res_handler_script" then
      table.insert(handlers, parser.parse_request_handler(child, source, ctx))
    elseif node_type == "request_separator" then
      name = get_node_field_text(child, "value", source)
    elseif node_type == "comment" and get_node_field_text(child, "name", source) == "name" then
      name = get_node_field_text(child, "value", source) or name
    end
  end
  if not name then
    if type(source) == "number" then
      local filename = vim.api.nvim_buf_get_name(source)
      name = filename:match(".*/%.?(.*).http$") or filename
      name = name .. "#" .. vim.b[source]._rest_nvim_count
      vim.b[source]._rest_nvim_count = vim.b[source]._rest_nvim_count + 1
    end
  end

  local headers = parse_headers(req_node, source, ctx)
  -- HACK: check if url doesn't have host
  if headers["host"] and vim.startswith(url, "/") then
    url = "http://" ..headers["host"][1]..url
    table.remove(headers["host"], 1)
  end
  ---@type rest.Request
  local req = {
    name = name,
    context = ctx,
    method = method,
    url = url,
    http_version = get_node_field_text(req_node, "version", source),
    headers = headers,
    cookies = {},
    body = body,
    handlers = handlers,
  }
  jar.load_cookies(req)
  return req
end

return parser
