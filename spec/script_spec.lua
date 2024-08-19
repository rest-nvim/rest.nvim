---@module 'luassert'

require("spec.minimum_init")

local parser = require("rest-nvim.parser")
local utils = require("rest-nvim.utils")
local Context = require("rest-nvim.context").Context

describe("handler script", function ()
  it("load handler script", function ()
    local ctx = Context:new()
    vim.env["foo"] = "old"
    vim.env["baz"] = "old"
    ctx:set("bar", "old")
    local script = [[
    client.global.set("foo", "new")
    request.variables.set("bar", "new")
    request.variables.set("baz", "new")
    ]]
    local h = require("rest-nvim.script.lua").load_post_req_hook(script, ctx)
    ---@diagnostic disable-next-line: missing-parameter
    h()
    assert.same("new", vim.env["foo"])
    assert.same("new", ctx:resolve("bar"))
    assert.same(nil, vim.env["bar"])
    assert.same("old", vim.env["baz"])
  end)
  it("alter response body", function ()
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
    local req_node = assert(tree:root():child(0))
    local req = assert(parser.parse(req_node, source))
    ---fake response
    ---@type rest.Response
    ---@diagnostic disable-next-line: missing-fields
    local res = {
      body = [[{"data": "given"}]]
    }
    vim.iter(req.handlers):each(function (f) f(res) end)
    assert.same([[{"data":"overwritten"}]], res.body)
  end)
  it("update context from response body", function ()
    local source = [[
http://localhost:8000

# @lang=lua
> {%
local json = vim.json.decode(response.body)
client.global.set("MYVAR", json.var)
%}
]]
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    local ctx = Context:new()
    local req = assert(parser.parse(req_node, source, ctx))
    ---@type rest.Response
    ---@diagnostic disable-next-line: missing-fields
    local res = {
      body = [[{"var": "boo"}]]
    }
    vim.iter(req.handlers):each(function (f) f(res) end)
    assert.same("boo", ctx:resolve("MYVAR"))
  end)
end)
