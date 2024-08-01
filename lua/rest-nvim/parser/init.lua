---@mod rest-nvim.pparser rest.nvim tree-sitter parsing module

local M = {}

local Context = require("rest-nvim.context").Context
local script = require("rest-nvim.script")
local utils   = require("rest-nvim.utils")
local logger   = require("rest-nvim.logger")
local config = require("rest-nvim.config")

---@alias Source integer|string Buffer or string which the `node` is extracted

---@alias BodyType "json"|"xml"|"external"|"form"|"graphql"

---@class ReqBody
---@field __TYPE BodyType
---@field data any

---@param node TSNode
---@param field string
---@param source Source
---@return string|nil
local function get_node_field_text(node, field, source)
  local n = node:field(field)[1]
  return n and vim.treesitter.get_node_text(n, source) or nil
end

---@param src string
---@param context Context
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
---@param context Context
---@return table<string,string> headers
local function parse_headers(req_node, source, context)
  local headers = {}
  local header_nodes = req_node:field("header")
  for _, node in ipairs(header_nodes) do
    local key = assert(get_node_field_text(node, "name", source))
    local value = assert(get_node_field_text(node, "value", source))
    key = expand_variables(key, context)
    value = expand_variables(value, context)
    key = string.lower(key)
    headers[key] = value
  end
  return headers
end

---@param body_node TSNode
---@param source Source
---@param context Context
---@return ReqBody|nil
function M.parse_body(body_node, source, context)
  local body = {}
  body.__TYPE = body_node:type():gsub("_%w+", "")
  ---@cast body ReqBody
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
    local parser = xml2lua.parser(handler)
    local ok = pcall(function (t) return parser:parse(t) end, body.data)
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
    body.data = {
      name = assert(get_node_field_text(body_node, "name", source)),
      path = assert(get_node_field_text(body_node, "path", source)),
    }
  elseif body.__TYPE == "graphql" then
    logger.error("graphql body is not supported yet")
  end
  return body
end

---parse all in-place variables from source
---@param source Source
---@return Context ctx
function M.create_context(source)
  local ctx = Context:new()
  local _, tree = utils.ts_parse_source(source)
  for node, _ in tree:root():iter_children() do
    if node:type() == "variable_declaration" then
      M.parse_variable_declaration(node, source, ctx)
    end
  end
  return ctx
end

---@return TSNode?
function M.get_cursor_request_node()
  local node = vim.treesitter.get_node()
  return node and utils.ts_find(node, "request")
end

---@return TSNode[]
function M.get_all_request_node()
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

---@param vd_node TSNode
---@param source Source
---@param ctx Context
function M.parse_variable_declaration(vd_node, source, ctx)
  local name = assert(get_node_field_text(vd_node, "name", source))
  local value = vim.trim(assert(get_node_field_text(vd_node, "value", source)))
  value = expand_variables(value, ctx)
  ctx:set(name, value)
end

---@param node TSNode
---@param source Source
---@param context Context
---@return function
function M.parse_script(node, source, context)
  vim.validate({ node = utils.ts_node_spec(node, "script") })
  local str = vim.treesitter.get_node_text(node, source):sub(3,-3)
  return script.load(str, context)
end

---@param script_node TSNode
---@param source Source
---@param context Context
function M.parse_pre_request_script(script_node, source, context)
  local node = assert(script_node:named_child(0))
  M.parse_script(node, source, context)()
end

---@param handler_node TSNode
---@param source Source
---@param context Context
function M.parse_request_handler(handler_node, source, context)
  local node = assert(handler_node:named_child(0))
  return M.parse_script(node, source, context)
end

---Parse the request node and create Request object. Returns `nil` if parsing
---failed.
---@param req_node TSNode Tree-sitter request node
---@param source Source
---@param context? Context
---@return Request_|nil
function M.parse(req_node, source, context)
  context = context or Context:new()
  -- request should not include error
  if req_node:has_error() then
    logger.error(utils.ts_node_error_log(req_node))
    return nil
  end
  local body_node = req_node:field("body")[1]
  local body = body_node and M.parse_body(body_node, source, context)
  if body_node and not body then
    logger.error("parsing body failed")
    return nil
  end
  local method = get_node_field_text(req_node, "method", source)
  if not method then
    logger.info("no method provided, falling back to 'GET'")
    method = "GET"
  end
  local url = expand_variables(
    assert(get_node_field_text(req_node, "url", source)),
    context,
    config.encode_url and utils.escape or nil
  )
  local pre_req_scripts = req_node:field("pre_request_script")
  for _, script_node in ipairs(pre_req_scripts) do
    M.parse_pre_request_script(script_node, source, context)
  end
  local handlers = vim.iter(req_node:field("handler_script")):map(function (node)
    return M.parse_request_handler(node, source, context)
  end):totable()
  ---@type Request_
  return {
    context = context,
    method = method,
    url = url,
    http_version = get_node_field_text(req_node, "version", source),
    headers = parse_headers(req_node, source, context),
    body = body,
    handlers = handlers,
  }
end

return M
