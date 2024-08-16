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
    assert.not_nil(req)
    ---@cast req rest.Request
    assert.same("http://example.com:8080/api/html/get?id=123&value=content", req.url)
  end)
end)

describe("url without host", function ()
  local source = open("spec/examples/url_without_host.http")
  local req_nodes = parser.get_all_request_nodes(source)
  assert.same(4, #req_nodes)
  it("host with non-secure port", function ()
    local req = parser.parse(req_nodes[1], source)
    assert.not_nil(req)
    ---@cast req rest.Request
    assert.same("http://example.com:8080/api", req.url)
  end)
  it("host with secure port", function ()
    local req = parser.parse(req_nodes[2], source)
    assert.not_nil(req)
    ---@cast req rest.Request
    assert.same("https://example.com:443/api", req.url)
  end)
  it("host with protocol", function ()
    local req = parser.parse(req_nodes[3], source)
    assert.not_nil(req)
    ---@cast req rest.Request
    assert.same("http://example.com/api", req.url)
  end)
  it("host without protocol", function ()
    local req = parser.parse(req_nodes[4], source)
    assert.not_nil(req)
    ---@cast req rest.Request
    assert.same("https://example.com/api", req.url)
  end)
end)
