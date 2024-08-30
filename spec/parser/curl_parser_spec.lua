---@module 'luassert'

require("spec.minimal_init")

local parser = require("rest-nvim.parser.curl")
local utils = require("rest-nvim.utils")

describe("curl cli parser", function()
    it("parse curl command", function()
        local source = [[
        curl -sSL -X POST https://example.com \
            -H 'Content-Type: application/json' \
            -d '{ "foo": 123 }'
        ]]
        local _, tree = utils.ts_parse_source(source, "bash")
        local curl_node = assert(tree:root():child(0))
        local args = parser.parse_command(curl_node, source)
        assert(args)
        assert.same({
            method = "POST",
            url = "https://example.com",
            headers = {
                ["content-type"] = { "application/json" },
            },
            body = {
                __TYPE = "raw",
                data = '{ "foo": 123 }',
            },
            meta = {
                redirect = true,
            },
            cookies = {},
            handlers = {},
        }, parser.parse_arguments(args))
    end)
end)
