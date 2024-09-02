---@module 'luassert'

require("spec.minimal_init")

local jar = require("rest-nvim.cookie_jar")
local utils = require("rest-nvim.utils")
local config = require("rest-nvim.config")

describe("Cookies unit tests", function()
    it("parse Set-Cookie header", function()
        local url = "http://example.dev"
        assert.is_same({
            name = "cookie1",
            value = "value1",
            domain = ".example.dev",
            path = "/",
            expires = -1,
        }, jar.parse_set_cookie(url, "cookie1=value1"))
        assert.is_same({
            name = "cookie2",
            value = "",
            domain = ".example.dev",
            path = "/",
            expires = -1,
        }, jar.parse_set_cookie(url, "cookie2="))
        assert.is_same({
            name = "cookie3",
            value = "value3",
            domain = ".example.com",
            path = "/",
            expires = -1,
        }, jar.parse_set_cookie(url, "cookie3=value3;domain=.example.com"))
        assert.is_same({
            name = "cookie4",
            value = "value4",
            domain = ".example.dev",
            path = "/some/valid-path",
            expires = -1,
        }, jar.parse_set_cookie(url, "cookie4=value4;path=/some/valid-path"))
        assert.is_same({
            name = "cookie5",
            value = "value5",
            domain = ".example.dev",
            path = "/",
            expires = 1723460761,
        }, jar.parse_set_cookie(url, "cookie5=value5; Path=/; Expires=Mon, 12 Aug 2024 11:06:01 GMT"))
    end)
    it("update jar from response", function()
        assert.is_same({}, jar.jar)
        ---@diagnostic disable-next-line: missing-fields
        jar.update_jar("http://example.dev", {
            headers = {
                ["set-cookie"] = {
                    "cookie1=value1",
                    "cookie2=value2;path=/some-path;cookie3=value3",
                },
            },
        })
        assert.is_same({
            {
                name = "cookie1",
                value = "value1",
                path = "/",
                expires = -1,
                domain = ".example.dev",
            },
            {
                name = "cookie2",
                value = "value2",
                path = "/some-path",
                expires = -1,
                domain = ".example.dev",
            },
        }, jar.jar)
        -- assert the cookies file
        local lines = vim.split(utils.read_file(config.cookies.path), "\n")
        assert.is_same({
            "# domain\tpath\tname\tvalue\texpires",
            ".example.dev\t/\tcookie1\tvalue1\t-1",
            ".example.dev\t/some-path\tcookie2\tvalue2\t-1",
            "",
        }, lines)
    end)
end)
