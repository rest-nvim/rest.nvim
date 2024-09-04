---@diagnostic disable: invisible
---@module 'luassert'

require("spec.minimal_init")
vim.g.rest_nvim = vim.tbl_deep_extend("force", {
    clients = {
        curl = {
            opts = {
                set_compressed = true,
            },
        },
    },
}, vim.g.rest_nvim)

local Context = require("rest-nvim.context").Context
local curl = require("rest-nvim.client.curl.cli")
local builder = curl.builder
local parser = curl.parser

local STAT_FORMAT = builder.STAT_ARGS[2]

describe("curl cli builder", function()
    it("from GET request", function()
        local args = builder.build({
            context = Context:new(),
            method = "GET",
            url = "http://localhost:8000",
            headers = {},
            cookies = {},
            handlers = {},
        })
        assert.same({ "http://localhost:8000", "-X", "GET", "-w", STAT_FORMAT }, args)
    end)
    it("from GET request with headers", function()
        local args = builder.build({
            context = Context:new(),
            method = "GET",
            url = "http://localhost:8000",
            headers = {
                ["x-foo"] = { "bar" },
            },
            cookies = {},
            handlers = {},
        })
        assert.same({ "http://localhost:8000", "-X", "GET", "-H", "X-Foo: bar", "-w", STAT_FORMAT }, args)
    end)
    it("from POST request with form body", function()
        local args = builder.build({
            context = Context:new(),
            method = "POST",
            url = "http://localhost:8000",
            headers = {},
            cookies = {},
            handlers = {},
            body = {
                __TYPE = "raw",
                data = "field1=value1&field2=value2",
            },
        })
        assert.same(
            { "http://localhost:8000", "-X", "POST", "--data-raw", "field1=value1&field2=value2", "-w", STAT_FORMAT },
            args
        )
    end)
    it("from POST request with json body", function()
        local json_text = [[{ "string": "foo", "number": 100, "array":  [1, 2, 3], "json": { "key": "value" } }]]
        local args = builder.build({
            context = Context:new(),
            method = "POST",
            url = "http://localhost:8000",
            headers = {},
            cookies = {},
            handlers = {},
            body = {
                __TYPE = "json",
                data = json_text,
            },
        })
        assert.same({ "http://localhost:8000", "-X", "POST", "--data-raw", json_text, "-w", STAT_FORMAT }, args)
    end)
    it("from POST request with external body", function()
        local args = builder.build({
            context = Context:new(),
            method = "POST",
            url = "http://localhost:8000",
            headers = {},
            cookies = {},
            handlers = {},
            body = {
                __TYPE = "external",
                data = {
                    path = "spec/test_server/post_json.json",
                },
            },
        })
        assert.same({
            "http://localhost:8000",
            "-X",
            "POST",
            "--data-binary",
            "@spec/test_server/post_json.json",
            "-w",
            STAT_FORMAT,
        }, args)
    end)
    it("with opts.set_compressed", function()
        local args = builder.build({
            context = Context:new(),
            method = "POST",
            url = "http://localhost:8000",
            headers = {
                ["accept-encoding"] = { "gzip" },
            },
            cookies = {},
            handlers = {},
        })
        assert.same({
            "http://localhost:8000",
            "--compressed",
            "-X",
            "POST",
            "-H",
            "Accept-Encoding: gzip",
            "-w",
            STAT_FORMAT,
        }, args)
    end)
end)

describe("curl cli response parser", function()
    it("from http GET request", function()
        local stdin = {
            "*   Trying 127.0.0.1:8000...",
            "* Connected to localhost (127.0.0.1) port 8000 (#0)",
            "> GET / HTTP/1.1",
            "> Host: localhost:8000",
            "> User-Agent: curl/7.81.0",
            "> Accept: */*",
            ">",
            "* Mark bundle as not supporting multiuse",
            "< HTTP/1.1 200 OK",
            "< Content-Type: text/plain",
            "< Date: Tue, 06 Aug 2024 12:22:44 GMT",
            "< Content-Length: 15",
            "<",
            "{ [15 bytes data]",
            "* Connection #0 to host localhost left intact",
        }
        local result = parser.parse_verbose(stdin)
        assert.same({
            request = {
                method = "GET",
                url = "/",
                http_version = "HTTP/1.1",
                headers = {
                    host = { "localhost:8000" },
                    ["user-agent"] = { "curl/7.81.0" },
                    accept = { "*/*" },
                },
            },
            response = {
                status = {
                    version = "HTTP/1.1",
                    code = 200,
                    text = "OK",
                },
                headers = {
                    ["content-type"] = { "text/plain" },
                    date = { "Tue, 06 Aug 2024 12:22:44 GMT" },
                    ["content-length"] = { "15" },
                },
            },
        }, result.requests[1])
    end)
    it("from redirected request", function()
        local stdin = {
            "*   Trying 127.0.0.1:8000...",
            "* Connected to localhost (127.0.0.1) port 8000 (#0)",
            -- first request
            "> GET /api/v1 HTTP/1.1",
            "> Host: localhost:8000",
            "> User-Agent: curl/7.81.0",
            "> Accept: */*",
            ">",
            --
            "* Mark bundle as not supporting multiuse",
            -- first response
            "< HTTP/1.1 301 Moved Permanently",
            "< Content-Type: text/html; charset=utf-8",
            "< Location: /api/v1/",
            "< Date: Tue, 03 Sep 2024 17:28:35 GMT",
            "< Content-Length: 43",
            "<",
            --
            "* Ignoring the response-body",
            "{ [43 bytes data]",
            "* Connection #0 to host localhost left intact",
            "* Issue another request to this URL: 'http://localhost:8000/api/v1/'",
            "* Found bundle for host localhost: 0xaaaac8b6bca0 [serially]",
            "* Can not multiplex, even if we wanted to!",
            "* Re-using existing connection! (#0) with host localhost",
            "* Connected to localhost (127.0.0.1) port 8000 (#0)",
            -- second request
            "> GET /api/v1/ HTTP/1.1",
            "> Host: localhost:8000",
            "> User-Agent: curl/7.81.0",
            "> Accept: */*",
            ">",
            --
            "* Mark bundle as not supporting multiuse",
            -- second response
            "< HTTP/1.1 200 OK",
            "< Date: Tue, 03 Sep 2024 17:28:35 GMT",
            "< Content-Length: 24",
            "< Content-Type: text/plain; charset=utf-8",
            "<",
            "{ [24 bytes data]",
            --
            "* Connection #0 to host localhost left intact",
        }
        local result = parser.parse_verbose(stdin)
        assert.same({
            request = {
                method = "GET",
                url = "/api/v1",
                http_version = "HTTP/1.1",
                headers = {
                    host = { "localhost:8000" },
                    ["user-agent"] = { "curl/7.81.0" },
                    accept = { "*/*" },
                },
            },
            response = {
                status = {
                    version = "HTTP/1.1",
                    code = 301,
                    text = "Moved Permanently",
                },
                headers = {
                    ["content-type"] = { "text/html; charset=utf-8" },
                    date = { "Tue, 03 Sep 2024 17:28:35 GMT" },
                    ["content-length"] = { "43" },
                    location = { "/api/v1/" },
                },
            },
        }, result.requests[1])
        assert.same({
            request = {
                method = "GET",
                url = "/api/v1/",
                http_version = "HTTP/1.1",
                headers = {
                    host = { "localhost:8000" },
                    ["user-agent"] = { "curl/7.81.0" },
                    accept = { "*/*" },
                },
            },
            response = {
                status = {
                    version = "HTTP/1.1",
                    code = 200,
                    text = "OK",
                },
                headers = {
                    ["content-type"] = { "text/plain; charset=utf-8" },
                    date = { "Tue, 03 Sep 2024 17:28:35 GMT" },
                    ["content-length"] = { "24" },
                },
            },
        }, result.requests[2])
    end)
end)

-- -- don't run real request on test by default
-- describe("curl cli request", function()
--   nio.tests.it("basic GET request", function()
--     local response = curl
--       .request({
--         context = Context:new(),
--         url = "https://reqres.in/api/users?page=5",
--         handlers = {},
--         headers = {},
--         cookies = {},
--         method = "GET",
--       })
--       .wait()
--     assert.same(
--       '{"page":5,"per_page":6,"total":12,"total_pages":2,"data":[],"support":{"url":"https://reqres.in/#support-heading","text":"To keep ReqRes free, contributions towards server costs are appreciated!"}}',
--       response.body
--     )
--     assert.same({
--         version = "HTTP/2",
--         code = 200,
--         text = ""
--     }, response.status)
--     -- HACK: have no idea how to make sure it is table<string,string>
--     assert.are_table(response.headers)
--   end)
--   nio.tests.it("basic POST request", function()
--     local response = curl
--       .request({
--         context = Context:new(),
--         url = "https://reqres.in/api/register",
--         handlers = {},
--         headers = {
--           ["content-type"] = { "application/json" }
--         },
--         cookies = {},
--         method = "POST",
--         body = {
--           __TYPE = "json",
--           data = '{ "email": "eve.holt@reqres.in", "password": "pistol" }',
--         }
--       })
--       .wait()
--     assert.same(
--       '{"id":4,"token":"QpwL5tke4Pnpja7X4"}',
--       response.body
--     )
--     assert.same({
--         version = "HTTP/2",
--         code = 200,
--         text = ""
--     }, response.status)
--     -- HACK: have no idea how to make sure it is table<string,string>
--     assert.are_table(response.headers)
--   end)
-- end)
