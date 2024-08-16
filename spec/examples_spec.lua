---@module 'luassert'

require("spec.minimum_init")

local parser = require("rest-nvim.parser")
local utils = require("rest-nvim.utils")

local function open(path)
  vim.cmd.edit(path)
  vim.cmd.source("ftplugin/http.lua")
  return 0
end

describe("multi-line-url", function ()
  it("line breaks should be ignored", function ()
    local source = open("spec/examples/multi_line_url.http")
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    local req = parser.parse(req_node, source)
    assert(req)
    assert.same("http://example.com:8080/api/html/get?id=123&value=content", req.url)
  end)
end)
