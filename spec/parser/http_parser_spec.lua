---@module 'luassert'

require("spec.minimum_init")

local parser = require("rest-nvim.parser")
local utils = require("rest-nvim.utils")

local function open(path)
  vim.cmd.edit(path)
  vim.cmd.source("ftplugin/http.lua")
  return 0
end

describe("parser", function ()
  it("parse form-urlencoded body", function ()
    local source = [[
POST https://ijhttp-examples.jetbrains.com/post
Content-Type: application/x-www-form-urlencoded

key1 = value1 &
key2 = value2 &
key3 = value3 &
key4 = value4 &
key5 = value5
]]
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    assert.same({
      method = "POST",
      url = "https://ijhttp-examples.jetbrains.com/post",
      headers = {
        ["content-type"] = { "application/x-www-form-urlencoded" },
      },
      cookies = {},
      handlers = {},
      body = {
        __TYPE = "form",
        data = {
          key1 = "value1",
          key2 = "value2",
          key3 = "value3",
          key4 = "value4",
          key5 = "value5",
        },
      },
    }, parser.parse(req_node, source))
  end)
  it("parse external body", function ()
    -- external body can be only sourced when
    local source = open("spec/examples/post_with_external_body.http")
    local _, tree = utils.ts_parse_source(source)
    local req_node = assert(tree:root():child(0))
    assert.same({
      method = "POST",
      url = "https://example.com:8080/api/html/post",
      headers = {
        ["content-type"] = { "application/json" },
      },
      cookies = {},
      handlers = {},
      body = {
        __TYPE = "external",
        data = {
          path = "spec/examples/input.json"
        }
      },
    }, parser.parse(req_node, source))
  end)
end)
