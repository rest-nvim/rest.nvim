---@module 'luassert'

local utils = require("rest-nvim.utils")

describe("tree-sitter utils", function ()
  local source = [[
http://localhost:8000

# @lang=lua
> {%
local json = vim.json.decode(response.body)
json.data = "overwritten"
response.body = vim.json.encode(json)
%}
]]
  local _, tree = utils.ts_parse_source(source)
  local script_node = assert(tree:root():child(0):child(1))
  assert.same("res_handler_script", script_node:type())
  local comment_node = assert(utils.ts_upper_node(script_node))
  assert.same("comment", comment_node:type())
end)
