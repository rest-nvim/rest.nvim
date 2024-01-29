---@mod rest-nvim.parser rest.nvim tree-sitter parsing module
---
---@brief [[
---
---Parsing module with tree-sitter, we use tree-sitter there to extract
---all the document nodes and their content from the HTTP files, then we
---start doing some other internal parsing like variables expansion and so on
---
---@brief ]]

local parser = {}

local logger = _G._rest_nvim.logger

---@alias NodesList { [string]: TSNode }[]
---@alias Variables { [string]: { type_: string, value: string|number|boolean } }[]

---Check if a given `node` has a syntax error and throw an error log message if that is the case
---@param node TSNode Tree-sitter node
---@return boolean
local function check_syntax_error(node)
  if node:has_error() then
    ---Create a node range string á la `:InspectTree` view
    ---@param n TSNode
    ---@return string
    local function create_node_range_str(n)
      local s_row, s_col = n:start()
      local e_row, e_col = n:end_()
      local range = "["

      if s_row == e_row then
        range = range .. s_row .. ":" .. s_col .. " - " .. e_col
      else
        range = range .. s_row .. ":" .. s_col .. " - " .. e_row .. ":" .. e_col
      end
      range = range .. "]"
      return range
    end

    ---@diagnostic disable-next-line need-check-nil
    logger:error("The tree-sitter node at the range " .. create_node_range_str(node) .. " has a syntax error and cannot be parsed")
    return true
  end

  return false
end

---Get a tree-sitter node at the cursor position
---@return TSNode|nil Tree-sitter node
---@return string|nil Node type
function parser.get_node_at_cursor()
  local node = assert(vim.treesitter.get_node())
  if check_syntax_error(node) then
    return nil, nil
  end

  return node, node:type()
end

---Small wrapper around `vim.treesitter.get_node_text` because I do not want to
---write it every time
---@see vim.treesitter.get_node_text
---@param node TSNode Tree-sitter node
---@param source integer|string Buffer or string from which the `node` is extracted
---@return string|nil
local function get_node_text(node, source)
  source = source or 0
  if check_syntax_error(node) then
    return nil
  end

  return vim.treesitter.get_node_text(node, source)
end

---Recursively look behind `node` until `query` node type is found
---@param node TSNode|nil Tree-sitter node, defaults to the node at the cursor position if not passed
---@param query string The tree-sitter node type that we are looking for
---@return TSNode|nil
function parser.look_behind_until(node, query)
  node = node or parser.get_node_at_cursor()

  -- There are no more nodes behind the `document` one
  ---@diagnostic disable-next-line need-check-nil
  if node:type() == "document" then
    ---@diagnostic disable-next-line need-check-nil
    logger:debug("Current node is document, which does not have any parent nodes, returning it instead")
    return node
  end

  ---@cast node TSNode
  if check_syntax_error(node) then
    return nil
  end

  ---@diagnostic disable-next-line need-check-nil
  local parent = assert(node:parent())
  if parent:type() ~= query then
    return parser.look_behind_until(parent, query)
  end

  return parent
end

---Traverse a request tree-sitter node and retrieve all its children nodes
---@param req_node TSNode Tree-sitter request node
---@return NodesList
local function traverse_request(req_node)
  local child_nodes = {}
  for child, _ in req_node:iter_children() do
    local child_type = child:type()
    child_nodes[child_type] = child
  end
  return child_nodes
end

---Traverse the document tree-sitter node and retrieve all the `variable_declaration` nodes
---@param document_node TSNode Tree-sitter document node
---@return Variables
local function traverse_variables(document_node)
  local variables = {}
  for child, _ in document_node:iter_children() do
    local child_type = child:type()
    if child_type == "variable_declaration" then
      local var_name = assert(get_node_text(child:field("name")[1], 0))
      local var_value = child:field("value")[1]
      local var_type = var_value:type()
      variables[var_name] = {
        type_ = var_type,
        value = assert(get_node_text(var_value, 0)),
      }
    end
  end
  return variables
end

---Parse all the variable nodes in the given node and expand them to their values
---@param node TSNode Tree-sitter node
---@param tree string The text where variables should be looked for
---@param text string The text where variables should be expanded
---@param variables Variables Document variables list
---@return string The given `text` with expanded variables
local function parse_variables(node, tree, text, variables)
  local variable_query = vim.treesitter.query.parse("http", "(variable name: (_) @name)")
  ---@diagnostic disable-next-line missing-parameter
  for _, nod, _ in variable_query:iter_captures(node:root(), tree) do
    local variable_name = assert(get_node_text(nod, tree))
    local variable = variables[variable_name]
    local variable_value = variable.value
    if variable.type_ == "string" then
      variable_value = variable_value:gsub('"', "")
    end
    text = text:gsub("{{[%s]?" .. variable_name .. "[%s]?}}", variable_value)
  end
  return text
end

---Parse a request tree-sitter node
---@param children_nodes NodesList Tree-sitter nodes
---@param variables Variables
---@return table
function parser.parse_request(children_nodes, variables)
  local request = {}
  for node_type, node in pairs(children_nodes) do
    if node_type == "method" then
      request.method = assert(get_node_text(node, 0))
    elseif node_type == "target_url" then
      request.url = assert(get_node_text(node, 0))
    end
  end

  -- Parse the request nodes again as a single string converted into a new AST Tree to expand the variables
  local request_text = request.method .. " " .. request.url .. "\n"
  local request_tree = vim.treesitter.get_string_parser(request_text, "http"):parse()[1]
  request.url = parse_variables(request_tree:root(), request_text, request.url, variables)

  return request
end

---Parse request headers tree-sitter nodes
---@param children_nodes NodesList Tree-sitter nodes
---@param variables Variables
---@return table
function parser.parse_headers(children_nodes, variables)
  local headers = {}
  for node_type, node in pairs(children_nodes) do
    if node_type == "header" then
      local name = assert(get_node_text(node:field("name")[1], 0))
      local value = assert(get_node_text(node:field("value")[1], 0))
      headers[name] = vim.trim(value)
    end
  end

  return headers
end

---Parse a request tree-sitter node body
---@param children_nodes NodesList Tree-sitter nodes
---@param variables Variables
---@return table
function parser.parse_body(children_nodes, variables)
  local body = {}
  for node_type, node in pairs(children_nodes) do
    -- TODO: handle XML bodies by using xml2lua library from luarocks
    if node_type == "json_body" then
      -- TODO: expand variables
      local json_body_text = assert(get_node_text(node, 0))
      local json_body = vim.json.decode(json_body_text, {
        luanil = { object = true, array = true },
      })
      body = json_body
    end
  end

  return body
end

function parser.parse(req_node)
  local ast = {
    request = {},
    headers = {},
    body = {},
  }
  local document_node = parser.look_behind_until(nil, "document")

  local request_children_nodes = traverse_request(req_node)
  ---@cast document_node TSNode
  local document_variables = traverse_variables(document_node)

  ast.request = parser.parse_request(request_children_nodes, document_variables)
  ast.headers = parser.parse_headers(request_children_nodes, document_variables)
  ast.body = parser.parse_body(request_children_nodes, document_variables)

  return ast
end

return parser
