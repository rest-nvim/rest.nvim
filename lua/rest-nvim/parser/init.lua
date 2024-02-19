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

local env_vars = require("rest-nvim.parser.env_vars")
local dynamic_vars = require("rest-nvim.parser.dynamic_vars")

---@alias NodesList { [string]: TSNode }[]
---@alias Variables { [string]: { type_: string, value: string|number|boolean } }[]

---Check if a given `node` has a syntax error and throw an error log message if that is the case
---@param node TSNode Tree-sitter node
---@return boolean
local function check_syntax_error(node)
  if node and node:has_error() then
    local logger = _G._rest_nvim.logger

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
    logger:error(
      "The tree-sitter node at the range " .. create_node_range_str(node) .. " has a syntax error and cannot be parsed"
    )
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
  local logger = _G._rest_nvim.logger
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
    if child_type ~= "header" then
      child_nodes[child_type] = child
    end
  end
  return child_nodes
end

---Traverse a request tree-sitter node and retrieve all its children header nodes
---@param req_node TSNode Tree-sitter request node
---@return NodesList An array-like table containing the request header nodes
local function traverse_headers(req_node)
  local headers = {}
  for child, _ in req_node:iter_children() do
    local child_type = child:type()
    if child_type == "header" then
      table.insert(headers, child)
    end
  end

  return headers
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
---@param variables Variables HTTP document variables list
---@return string|nil The given `text` with expanded variables
local function parse_variables(node, tree, text, variables)
  local logger = _G._rest_nvim.logger
  local variable_query = vim.treesitter.query.parse("http", "(variable name: (_) @name)")
  ---@diagnostic disable-next-line missing-parameter
  for _, nod, _ in variable_query:iter_captures(node:root(), tree) do
    local variable_name = assert(get_node_text(nod, tree))
    local variable_value

    -- If the variable name contains a `$` symbol then try to parse it as a dynamic variable
    if variable_name:find("^%$") then
      variable_value = dynamic_vars.read(variable_name)
      if variable_value then
        return variable_value
      end
    end

    local variable = variables[variable_name]
    -- If the variable was not found in the document then fallback to the shell environment
    if not variable then
      ---@diagnostic disable-next-line need-check-nil
      logger:debug(
        "The variable '" .. variable_name .. "' was not found in the document, falling back to the environment ..."
      )
      env_vars.read_file()
      local env_var = vim.env[variable_name]
      if not env_var then
        ---@diagnostic disable-next-line need-check-nil
        logger:warn(
          "The variable '"
            .. variable_name
            .. "' was not found in the document or in the environment. Returning the string as received ..."
        )
        return text
      end
      variable_value = env_var
    else
      variable_value = variable.value
      if variable.type_ == "string" then
        ---@cast variable_value string
        variable_value = variable_value:gsub('"', "")
      end
    end
    text = text:gsub("{{[%s]?" .. variable_name .. "[%s]?}}", variable_value)
  end
  return text
end

---Parse a request tree-sitter node
---@param children_nodes NodesList Tree-sitter nodes
---@param variables Variables HTTP document variables list
---@return table A table containing the request target `url` and `method` to be used
function parser.parse_request(children_nodes, variables)
  local request = {}
  for node_type, node in pairs(children_nodes) do
    if node_type == "method" then
      request.method = assert(get_node_text(node, 0))
    elseif node_type == "target_url" then
      request.url = assert(get_node_text(node, 0))
    elseif node_type == "http_version" then
      local http_version = assert(get_node_text(node, 0))
      request.http_version = http_version:gsub("HTTP/", "")
    end
  end

  -- Parse the request nodes again as a single string converted into a new AST Tree to expand the variables
  local request_text = request.method .. " " .. request.url .. "\n"
  local request_tree = vim.treesitter.get_string_parser(request_text, "http"):parse()[1]
  request.url = parse_variables(request_tree:root(), request_text, request.url, variables)

  return request
end

---Parse request headers tree-sitter nodes
---@param header_nodes NodesList Tree-sitter nodes
---@param variables Variables HTTP document variables list
---@return table A table containing the headers in a key-value style
function parser.parse_headers(header_nodes, variables)
  local headers = {}
  for _, node in ipairs(header_nodes) do
    local name = assert(get_node_text(node:field("name")[1], 0))
    local value = vim.trim(assert(get_node_text(node:field("value")[1], 0)))

    -- This dummy request is just for the parser to be able to recognize the header node
    -- so we can iterate over it to parse the variables
    local dummy_request = "GET http://localhost:3333\n"
    local header_text = name .. ": " .. value
    local header_tree = vim.treesitter.get_string_parser(dummy_request .. header_text, "http"):parse()[1]

    headers[name] = parse_variables(header_tree:root(), dummy_request .. header_text, value, variables)
  end

  return headers
end

---Recursively traverse a body table and expand all the variables
---@param tbl table Request body
---@return table
local function traverse_body(tbl, variables)
  ---Expand a variable in the given string
  ---@param str string String where the variables are going to be expanded
  ---@param vars Variables HTTP document variables list
  ---@return string|number|boolean
  local function expand_variable(str, vars)
    local logger = _G._rest_nvim.logger

    local variable_name = str:gsub("{{[%s]?", ""):gsub("[%s]?}}", ""):match(".*")
    local variable_value

    -- If the variable name contains a `$` symbol then try to parse it as a dynamic variable
    if variable_name:find("^%$") then
      variable_value = dynamic_vars.read(variable_name)
      if variable_value then
        return variable_value
      end
    end

    local variable = vars[variable_name]
    -- If the variable was not found in the document then fallback to the shell environment
    if not variable then
      ---@diagnostic disable-next-line need-check-nil
      logger:debug(
        "The variable '" .. variable_name .. "' was not found in the document, falling back to the environment ..."
      )
      env_vars.read_file()
      local env_var = vim.env[variable_name]
      if not env_var then
        ---@diagnostic disable-next-line need-check-nil
        logger:warn(
          "The variable '"
            .. variable_name
            .. "' was not found in the document or in the environment. Returning the string as received ..."
        )
        return str
      end
      variable_value = env_var
    else
      variable_value = variable.value
      if variable.type_ == "string" then
        ---@cast variable_value string
        variable_value = variable_value:gsub('"', "")
      end
    end
    ---@cast variable_value string|number|boolean
    return variable_value
  end

  for k, v in pairs(tbl) do
    if type(v) == "table" then
      traverse_body(v, variables)
    end

    if type(k) == "string" and k:find("{{[%s]?.*[%s]?}}") then
      local variable_value = expand_variable(k, variables)
      local key_value = tbl[k]
      tbl[k] = nil
      tbl[variable_value] = key_value
    end
    if type(v) == "string" and v:find("{{[%s]?.*[%s]?}}") then
      local variable_value = expand_variable(v, variables)
      tbl[k] = variable_value
    end
  end

  return tbl
end

---Parse a request tree-sitter node body
---@param children_nodes NodesList Tree-sitter nodes
---@param variables Variables HTTP document variables list
---@return table Decoded body table
function parser.parse_body(children_nodes, variables)
  local body = {}

  -- TODO: handle GraphQL bodies by using a graphql parser library from luarocks
  for node_type, node in pairs(children_nodes) do
    if node_type == "json_body" then
      local json_body_text = assert(get_node_text(node, 0))
      local json_body = vim.json.decode(json_body_text, {
        luanil = { object = true, array = true },
      })
      body = traverse_body(json_body, variables)
      -- This is some metadata to be used later on
      body.__TYPE = "json"
    elseif node_type == "xml_body" then
      local found_xml2lua, xml2lua = pcall(require, "xml2lua")
      if found_xml2lua then
        local xml_handler = require("xmlhandler.tree")

        local body_handler = xml_handler:new()
        local xml_parser = xml2lua.parser(body_handler)
        local xml_body_text = assert(get_node_text(node, 0))
        xml_parser:parse(xml_body_text)
        body = traverse_body(body_handler.root, variables)
      end
      -- This is some metadata to be used later on
      body.__TYPE = "xml"
    elseif node_type == "external_body" then
      -- < @ (identifier) (file_path name: (path))
      -- 0 1      2                 3
      if node:child_count() > 2 then
        body.name = assert(get_node_text(node:child(2), 0))
      end
      body.path = assert(get_node_text(node:field("file_path")[1], 0))
      -- This is some metadata to be used later on
      body.__TYPE = "external_file"
    elseif node_type == "form_data" then
      local names = node:field("name")
      local values = node:field("value")
      if vim.tbl_count(names) > 1 then
        for idx, name in ipairs(names) do
          ---@type string|number|boolean
          local value = assert(get_node_text(values[idx], 0)):gsub('"', "")
          body[assert(get_node_text(name, 0))] = value
        end
      else
        ---@type string|number|boolean
        local value = assert(get_node_text(values[1], 0)):gsub('"', "")
        body[assert(get_node_text(names[1], 0))] = value
      end
      -- This is some metadata to be used later on
      body.__TYPE = "form"
    end
  end

  return body
end

---Get a script variable node and return its content
---@param req_node TSNode Tree-sitter request node
---@return string Script variables content
function parser.parse_script(req_node)
  -- Get the next named sibling of the current request node,
  -- if the request does not have any sibling or if it is not
  -- a script_variable node then early return an empty string
  local next_sibling = req_node:next_named_sibling()
  ---@diagnostic disable-next-line need-check-nil
  if not next_sibling or next_sibling and next_sibling:type() ~= "script_variable" then
    return ""
  end

  return assert(get_node_text(next_sibling, 0))
end

---@class RequestReq
---@field method string The request method
---@field url string The request URL
---@field http_version? string The request HTTP protocol

---@class Request
---@field request RequestReq
---@field headers { [string]: string|number|boolean }[]
---@field body table
---@field script? string
---@field start number
---@field end_ number

---Parse a request and return the request on itself, its headers and body
---@param req_node TSNode Tree-sitter request node
---@return Request Table containing the request data
function parser.parse(req_node)
  local ast = {
    request = {},
    headers = {},
    body = {},
    script = "",
  }
  local document_node = parser.look_behind_until(nil, "document")

  local request_children_nodes = traverse_request(req_node)
  local request_header_nodes = traverse_headers(req_node)

  ---@cast document_node TSNode
  local document_variables = traverse_variables(document_node)

  ast.request = parser.parse_request(request_children_nodes, document_variables)
  ast.headers = parser.parse_headers(request_header_nodes, document_variables)
  ast.body = parser.parse_body(request_children_nodes, document_variables)
  ast.script = parser.parse_script(req_node)

  -- Request node range
  ast.start = req_node:start()
  ast.end_ = req_node:end_()

  return ast
end

return parser
