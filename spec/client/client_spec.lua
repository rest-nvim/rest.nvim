---@module 'luassert'

local clients = require("rest-nvim.client")

describe("request clients", function()
    it("get_available_clients", function()
        local req = {
            method = "GET",
            url = "https://duckduckgo.com?q=https://duckduckgo.com",
            headers = {},
            cookies = {},
            handlers = {},
        }
        local available_clients = clients.get_available_clients(req)
        assert.same(1, #available_clients)
    end)
end)
