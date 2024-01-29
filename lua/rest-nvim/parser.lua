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
---@return string|nil
local function get_node_text(node)
  if check_syntax_error(node) then
    return nil
  end

  return vim.treesitter.get_node_text(node, 0)
end

---Recursively look behind `node` until `query` node type is found
---@param node TSNode|nil Tree-sitter node, defaults to the node at the cursor position if not passed
---@param query string The tree-sitter node type that we are looking for
---@return TSNode|nil
function parser.look_behind_until(node, query)
  if not node then
    node = parser.get_node_at_cursor()
  end

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
      local var_name = assert(get_node_text(child:field("name")[1]))
      local var_value = child:field("value")[1]
      local var_type = var_value:type()
      variables[var_name] = {
        type_ = var_type,
        value = assert(get_node_text(var_value)),
      }
    end
  end
  return variables
end

---Parse all the variable nodes in the document node
---@param children_nodes NodesList Tree-sitter nodes
---@return table
function parser.parse_variable(children_nodes)
  local variables = {}

  return variables
end

---Parse a request tree-sitter node
---@param children_nodes NodesList Tree-sitter nodes
---@param variables {}
---@return table
function parser.parse_request(children_nodes, variables)
  local request = {}
  for node_type, node in pairs(children_nodes) do
    -- ast.request
    if node_type == "method" then
      request.method = assert(get_node_text(node))
    elseif node_type == "target_url" then
      local url_node_text = assert(get_node_text(node))
      local url_variable = url_node_text:match("{{[%s]?%w+[%s]?}}")
    end

    -- ast.headers
    -- if node_type == "header" then
    --   local header_name = assert(get_node_text(node:field("name")[1]))
    --   local header_value = assert(get_node_text(node:field("value")[1]))
    --   ast.headers[header_name] = vim.trim(header_value)
    -- end

    -- ast.body
    -- TODO: parse XML and GraphQL, how so?
    -- if node_type == "json_body" then
    --   local json_body_text = assert(get_node_text(node))
    --   local json_body = vim.json.decode(json_body_text, {
    --     luanil = {
    --       object = true,
    --       array = true,
    --     }
    --   })
    --
    --   ast.body = json_body
    -- end
  end

  return request
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

  vim.print(document_variables)

  ast.request = parser.parse_request(request_children_nodes, document_variables)

  return ast
end

return parser
