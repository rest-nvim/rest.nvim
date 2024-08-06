---@module 'luassert'

require("spec.minimum_init")

local parser = require("rest-nvim.parser")
local utils = require("rest-nvim.utils")
local context = require("rest-nvim.context").Context
local logger = require("rest-nvim.logger")

local spy = require("luassert.spy")

local function file(path)
  vim.cmd.edit(path)
  return 0
end

describe("parser", function()
  it("validate http parser", function()
    assert.same("http", vim.treesitter.language.get_lang("http"))
  end)
  it("parse from http string", function()
    local source="GET https://github.com\n"
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    assert.same({
      context = context:new(),
      method = "GET",
      url = "https://github.com",
      headers = {},
      handlers = {},
    }, parser.parse(req_node, source))
  end)
  it("parse from http file", function()
    local source = file "spec/api.http"
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    assert.same({
      context = context:new(),
      method = "GET",
      url = "https://api.github.com/users/boltlessengineer",
      headers = {
        ["user-agent"] = "neovim"
      },
      handlers = {},
    }, parser.parse(req_node, source))
  end)
  it("parse json", function ()
    local source = "POST https://example.com\n\n{\n\t\"blah\": 1}\n"
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    assert.same({
      context = context:new(),
      method = "POST",
      url = "https://example.com",
      headers = {},
      handlers = {},
      body = {
        __TYPE = "json",
        data = "{\n\t\"blah\": 1}"
      },
    }, parser.parse(req_node, source))
  end)
  it("parse invalid json", function ()
    local source = "POST https://example.com\n\n{\n\t\"blah\": 1\n"
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    local spy_log_warn = spy.on(logger, "warn")
    parser.parse(req_node, source)
    assert.spy(spy_log_warn).called_with("invalid json: '{\n\t\"blah\": 1'")
  end)
  it("parse xml", function ()
    local source = [[POST https://example.com

<?xml version="1.0" encoding="utf-8"?>
<Request>
  <Login>login</Login>
  <Password>password</Password>
</Request>
]]
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    assert.same({
      context = context:new(),
      method = "POST",
      url = "https://example.com",
      headers = {},
      handlers = {},
      body = {
        __TYPE = "xml",
        data = [[<?xml version="1.0" encoding="utf-8"?>
<Request>
  <Login>login</Login>
  <Password>password</Password>
</Request>]],
      },
    }, parser.parse(req_node, source))
  end)
  it("parse invalid xml", function ()
    logger.info("hi")
    local source = "POST https://example.com\n\n<?xml\n"
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    local spy_log_warn = spy.on(logger, "warn")
    parser.parse(req_node, source)
    assert.spy(spy_log_warn).called_with("invalid xml: '<?xml'")
  end)
  it("parse with variables in header", function ()
    local source = [[POST https://example.com
HOST: {{$date}}
]]
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    local req = parser.parse(req_node, source)
    assert.is_not_nil(req)
    ---@cast req Request
    assert.same({
      host = os.date("%Y-%m-%d")
    }, req.headers)
  end)
  it("parse with variables in header", function ()
    vim.env["DATE"] = "2024-07-28"
    local source = [[POST https://example.com

{
  "name": "{{DATE}}"
}
]]
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    local req = parser.parse(req_node, source)
    assert.is_not_nil(req)
    ---@cast req Request
    assert.same({
      __TYPE = "json",
      data = [[{
  "name": "2024-07-28"
}]]
    }, req.body)
  end)
  it("parse variable declaration", function ()
    local source = "@foo = bar\n"
    local _, tree = utils.ts_parse_source(source)
    local vd_node = assert(tree:root():child(0))
    assert.same("variable_declaration", vd_node:type())
    local c = context:new()
    parser.parse_variable_declaration(vd_node, source, c)
    assert.same({
      foo = "bar"
    }, c.vars)
  end)
  it("parse variable declaration with other variable", function ()
    local source = "@foo = bar\n@baz = {{foo}} {{$date}}"
    local _, tree = utils.ts_parse_source(source)
    local c = context:new()
    parser.parse_variable_declaration(assert(tree:root():child(0)), source, c)
    parser.parse_variable_declaration(assert(tree:root():child(1)), source, c)
    assert.same({
      foo = "bar",
      baz = "bar " .. os.date("%Y-%m-%d"),
    }, c.vars)
  end)
  it("parse pre-request script", function ()
    local source = "< {%\nrequest.variables.set('foo', 'bar')\n%}\n"
    local _, tree = utils.ts_parse_source(source)
    local c = context:new()
    local script_node = tree:root():child(0)
    assert(script_node)
    assert.same("pre_request_script", script_node:type())
    parser.parse_pre_request_script(script_node, source, c)
    assert.same({
      foo = "bar",
    }, c.vars)
  end)
  it("create context from source", function ()
    local source = [[
@foo=bar
@bar=1234
@baz={{foo}} adsf
]]
    local ctx = parser.create_context(source)
    assert.same({
      foo = "bar",
      bar = "1234",
      baz = "bar adsf",
    }, ctx.vars)
  end)
  it("handler script", function ()
    local ctx = context:new()
    vim.env["foo"] = "old"
    vim.env["baz"] = "old"
    ctx:set("bar", "old")
    local script = [[
    client.global.set("foo", "new")
    request.variables.set("bar", "new")
    request.variables.set("baz", "new")
    ]]
    local h = require("rest-nvim.script").load_handler(script, ctx)
    h()
    assert.same("new", vim.env["foo"])
    assert.same("new", ctx:resolve("bar"))
    assert.same(nil, vim.env["bar"])
    assert.same("old", vim.env["baz"])
  end)
end)
