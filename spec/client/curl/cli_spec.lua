---@diagnostic disable: invisible
---@module 'luassert'

require("spec.minimal_init")
vim.g.rest_nvim = vim.tbl_deep_extend("force", {
    clients = {
        curl = {
            opts = {
                set_compressed = true,
                certificates = {},
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
        local response = parser.parse_verbose(stdin)
        assert.same({
            status = {
                version = "HTTP/1.1",
                code = 200,
                text = "OK",
            },
            statistics = {},
            headers = {
                ["content-type"] = { "text/plain" },
                date = { "Tue, 06 Aug 2024 12:22:44 GMT" },
                ["content-length"] = { "15" },
            },
        }, response)
    end)
    it("Redirected response", function()
        local stdin = {
            "*   Trying 34.78.67.165:80...",
            "* Connected to ijhttp-examples.jetbrains.com (34.78.67.165) port 80 (#0)",
            -- request
            "> POST /post HTTP/1.1",
            "> Host: ijhttp-examples.jetbrains.com",
            "> User-Agent: curl/7.81.0",
            "> Accept: */*",
            ">",
            "* Mark bundle as not supporting multiuse",
            -- resopnse (301)
            "< HTTP/1.1 301 Moved Permanently",
            "< Date: Sun, 09 Feb 2025 15:25:31 GMT",
            "< Content-Type: text/html",
            "< Content-Length: 162",
            "< Connection: keep-alive",
            "< Location: http://examples.http-client.intellij.net/post",
            "<",
            "* Ignoring the response-body",
            "* Connection #0 to host ijhttp-examples.jetbrains.com left intact",
            "* Issue another request to this URL: 'http://examples.http-client.intellij.net/post'",
            "*   Trying 34.78.67.165:80...",
            "* Connected to examples.http-client.intellij.net (34.78.67.165) port 80 (#1)",
            -- request
            "> POST /post HTTP/1.1",
            "> Host: examples.http-client.intellij.net",
            "> User-Agent: curl/7.81.0",
            "> Accept: */*",
            ">",
            "* Mark bundle as not supporting multiuse",
            -- response (308)
            "< HTTP/1.1 308 Permanent Redirect",
            "< Date: Sun, 09 Feb 2025 15:25:32 GMT",
            "< Content-Type: text/html",
            "< Content-Length: 164",
            "< Connection: keep-alive",
            "< Location: https://examples.http-client.intellij.net/post",
            "<",
            "* Ignoring the response-body",
            "* Connection #1 to host examples.http-client.intellij.net left intact",
            "* Clear auth, redirects to port from 80 to 443",
            "* Issue another request to this URL: 'https://examples.http-client.intellij.net/post'",
            "*   Trying 34.78.67.165:443...",
            "* Connected to examples.http-client.intellij.net (34.78.67.165) port 443 (#2)",
            "* ALPN, offering h2",
            "* ALPN, offering http/1.1",
            "*  CAfile: /etc/ssl/certs/ca-certificates.crt",
            "*  CApath: /etc/ssl/certs",
            "* TLSv1.0 (OUT), TLS header, Certificate Status (22):",
            "* TLSv1.3 (OUT), TLS handshake, Client hello (1):",
            "* TLSv1.2 (IN), TLS header, Certificate Status (22):",
            "* TLSv1.3 (IN), TLS handshake, Server hello (2):",
            "* TLSv1.2 (IN), TLS header, Finished (20):",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* TLSv1.3 (IN), TLS handshake, Certificate (11):",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* TLSv1.3 (IN), TLS handshake, CERT verify (15):",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* TLSv1.3 (IN), TLS handshake, Finished (20):",
            "* TLSv1.2 (OUT), TLS header, Finished (20):",
            "* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):",
            "* TLSv1.2 (OUT), TLS header, Supplemental data (23):",
            "* TLSv1.3 (OUT), TLS handshake, Finished (20):",
            "* SSL connection using TLSv1.3 / TLS_AES_256_GCM_SHA384",
            "* ALPN, server accepted to use h2",
            "* Server certificate:",
            "*  subject: CN=examples.http-client.intellij.net",
            "*  start date: Feb  9 08:45:35 2025 GMT",
            "*  expire date: May 10 08:45:34 2025 GMT",
            [[*  subjectAltName: host "examples.http-client.intellij.net" matched cert's "examples.http-client.intellij.net"]],
            "*  issuer: C=US; O=Let's Encrypt; CN=R11",
            "*  SSL certificate verify ok.",
            "* Using HTTP2, server supports multiplexing",
            "* Connection state changed (HTTP/2 confirmed)",
            "* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0",
            "* TLSv1.2 (OUT), TLS header, Supplemental data (23):",
            "* TLSv1.2 (OUT), TLS header, Supplemental data (23):",
            "* TLSv1.2 (OUT), TLS header, Supplemental data (23):",
            "* Using Stream ID: 1 (easy handle 0xaf9f59cebcc0)",
            "* TLSv1.2 (OUT), TLS header, Supplemental data (23):",
            -- request
            "> POST /post HTTP/2",
            "> Host: examples.http-client.intellij.net",
            "> user-agent: curl/7.81.0",
            "> accept: */*",
            ">",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* TLSv1.3 (IN), TLS handshake, Newsession Ticket (4):",
            "* old SSL session ID is stale, removing",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* Connection state changed (MAX_CONCURRENT_STREAMS == 128)!",
            "* TLSv1.2 (OUT), TLS header, Supplemental data (23):",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            -- response (200)
            "< HTTP/2 200",
            "< date: Sun, 09 Feb 2025 15:25:32 GMT",
            "< content-type: application/json",
            "< content-length: 419",
            "< vary: Accept-Encoding",
            "< access-control-allow-origin: https://examples.http-client.intellij.net",
            "< access-control-allow-credentials: true",
            "< strict-transport-security: max-age=31536000; includeSubDomains",
            "<",
            "* TLSv1.2 (IN), TLS header, Supplemental data (23):",
            "* Connection #2 to host examples.http-client.intellij.net left intact",
        }
        local response = parser.parse_verbose(stdin)
        assert.same({
            status = {
                version = "HTTP/2",
                code = 200,
                text = "",
            },
            statistics = {},
            headers = {
                date = { "Sun, 09 Feb 2025 15:25:32 GMT" },
                ["content-type"] = { "application/json" },
                ["content-length"] = { "419" },
                ["vary"] = { "Accept-Encoding" },
                ["access-control-allow-origin"] = { "https://examples.http-client.intellij.net" },
                ["access-control-allow-credentials"] = { "true" },
                ["strict-transport-security"] = { "max-age=31536000; includeSubDomains" },
            },
        }, response)
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
