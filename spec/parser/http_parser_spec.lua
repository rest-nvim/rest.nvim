---@module 'luassert'

require("spec.minimal_init")

local parser = require("rest-nvim.parser")
local utils = require("rest-nvim.utils")
local context = require("rest-nvim.context").Context
local logger = require("rest-nvim.logger")

local spy = require("luassert.spy")

local function open(path)
    vim.cmd.edit(path)
    return 0
end

---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function() end

describe("http parser", function()
    it("validate http parser", function()
        assert.same("http", vim.treesitter.language.get_lang("http"))
    end)
    it("parse from http string", function()
        local source = "GET https://github.com\n"
        local _, tree = utils.ts_parse_source(source)
        local req_node = assert(tree:root():child(0))
        assert.same({
            method = "GET",
            url = "https://github.com",
            headers = {},
            cookies = {},
            handlers = {},
        }, parser.parse(req_node, source))
    end)
    it("parse from http file", function()
        local source = open("spec/examples/basic_get.http")
        local _, tree = utils.ts_parse_source(source)
        local req_node = assert(tree:root():child(0))
        assert.same({
            name = "basic get statement",
            method = "GET",
            url = "https://api.github.com/users/boltlessengineer",
            headers = {
                ["user-agent"] = { "neovim" },
            },
            cookies = {},
            handlers = {},
        }, parser.parse(req_node, source))
    end)
    it("capture all request names", function()
        local source = [[
### first named request
GET http://localhost:80
### request separator that isn't a request name
###
# @name=second named request
# additional comments
GET http://localhost:80
]]
        local names = parser.get_request_names(source)
        assert.same({ "first named request", "second named request" }, names)
    end)
    it("parse request with host header", function()
        local source = [[
GET /some/path
HOST: localhost:8000
]]
        local _, tree = utils.ts_parse_source(source)
        local req_node = assert(tree:root():child(0))
        local req = assert(parser.parse(req_node, source))
        assert.same("http://localhost:8000/some/path", req.url)
    end)
    it("parse request with headers", function()
        local source = [[
http://example.com/api
X-Header1: value1
X-Header2:
X-Header1: value2
]]
        local _, tree = utils.ts_parse_source(source)
        local req_node = assert(tree:root():child(0))
        assert.same({
            url = "http://example.com/api",
            method = "GET",
            headers = {
                ["x-header1"] = { "value1", "value2" },
                ["x-header2"] = {},
            },
            handlers = {},
            cookies = {},
        }, parser.parse(req_node, source))
    end)

    describe("parse body", function()
        it("json body", function()
            local source = 'POST https://example.com\n\n{\n\t"blah": 1}\n'
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(0))
            assert.same({
                method = "POST",
                url = "https://example.com",
                headers = {},
                cookies = {},
                handlers = {},
                body = {
                    __TYPE = "json",
                    data = '{\n\t"blah": 1}',
                },
            }, parser.parse(req_node, source))
        end)
        it("invalid json body", function()
            local source = 'POST https://example.com\n\n{\n\t"blah": 1\n'
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(0))
            local spy_log_warn = spy.on(logger, "warn")
            parser.parse(req_node, source)
            ---@diagnostic disable-next-line: undefined-field
            assert.spy(spy_log_warn).called_with("invalid json: '{\n\t\"blah\": 1'")
        end)
        it("parse xml", function()
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
                method = "POST",
                url = "https://example.com",
                headers = {},
                cookies = {},
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
        it("parse invalid xml", function()
            logger.info("hi")
            local source = "POST https://example.com\n\n<?xml\n"
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(0))
            local spy_log_warn = spy.on(logger, "warn")
            parser.parse(req_node, source)
            ---@diagnostic disable-next-line: undefined-field
            assert.spy(spy_log_warn).called_with("invalid xml: '<?xml'")
        end)
        it("parse form-urlencoded body", function()
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
                    __TYPE = "raw",
                    data = "key1=value1&key2=value2&key3=value3&key4=value4&key5=value5",
                },
            }, parser.parse(req_node, source))
        end)
        it("parse external body", function()
            -- external body can be only sourced when
            local source = open("spec/examples/request_body/external_body.http")
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(1))
            assert.same({
                method = "POST",
                url = "https://example.com:8080/api/html/post",
                headers = {},
                cookies = {},
                handlers = {},
                name = "External body",
                body = {
                    __TYPE = "external",
                    data = {
                        path = "spec/examples/request_body/input.json",
                        content = '{\n    "foo": "baz"\n}\n',
                    },
                },
            }, parser.parse(req_node, source))
        end)
        it("parse external body (raw)", function()
            -- external body can be only sourced when
            local source = open("spec/examples/request_body/external_body.http")
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(2))
            assert.same({
                method = "POST",
                url = "https://example.com:8080/api/html/post",
                headers = {},
                cookies = {},
                handlers = {},
                name = "External body (raw)",
                body = {
                    __TYPE = "external",
                    data = {
                        path = "spec/examples/request_body/input.json",
                    },
                },
            }, parser.parse(req_node, source))
        end)
        it("parse graphql body", function()
            local source = open("spec/examples/request_body/graphql.http")
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(1))
            local req = parser.parse(req_node, source)
            assert(req)
            assert.same("POST", req.method)
            assert.same("graphql", req.body.__TYPE)
            assert.same({
                query = [[query ($name: String!, $owner: String!) {
    repository(name: $name, owner: $owner) {
        name
            fullName: nameWithOwner
            description
            diskUsage
            forkCount
            stargazers(first: 5) {
                totalCount
                nodes {
                    login
                    name
                }
            }
        watchers {
            totalCount
        }
    }
}
]],
                variables = {
                    name = "NativeVim",
                    owner = "boltlessengineer",
                },
            }, vim.json.decode(req.body.data))
        end)
    end)

    describe("variables", function()
        it("parse with variables in header", function()
            vim.env["TOKEN"] = "xxx"
            local source = [[POST https://example.com
Authorization: Bearer {{TOKEN}}
]]
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(0))
            local req = parser.parse(req_node, source)
            assert.not_nil(req)
            ---@cast req rest.Request
            assert.same({
                ["authorization"] = { "Bearer xxx" },
            }, req.headers)
        end)
        it("parse with variables in body", function()
            vim.env["DATE"] = "2024-07-28"
            local source = [[POST https://example.com

{
  "date": "{{DATE}}"
}
]]
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(0))
            local req = parser.parse(req_node, source)
            assert.not_nil(req)
            ---@cast req rest.Request
            assert.same({
                __TYPE = "json",
                data = [[{
  "date": "2024-07-28"
}]],
            }, req.body)
        end)
        it("parse variable declaration", function()
            local source = "@foo = bar\n"
            local _, tree = utils.ts_parse_source(source)
            local vd_node = assert(tree:root():child(0):child(0))
            assert.same("variable_declaration", vd_node:type())
            local c = context:new()
            parser.parse_variable_declaration(vd_node, source, c)
            assert.same({
                foo = "bar",
            }, c.vars)
        end)
        it("parse variable declaration with other variable", function()
            local source = "@foo = bar\n@baz = {{foo}} {{$date}}\n"
            local _, tree = utils.ts_parse_source(source)
            local c = context:new()
            parser.parse_variable_declaration(assert(tree:root():child(0):child(0)), source, c)
            parser.parse_variable_declaration(assert(tree:root():child(0):child(1)), source, c)
            assert.same({
                foo = "bar",
                baz = "bar " .. os.date("%Y-%m-%d"),
            }, c.vars)
        end)
    end)

    it("parse pre-request script", function()
        local source = "# @lang=lua\n< {%\nrequest.variables.set('foo', 'bar')\n%}\n"
        local _, tree = utils.ts_parse_source(source)
        local c = context:new()
        local script_node = tree:root():child(0):child(1)
        assert(script_node)
        assert.same("pre_request_script", script_node:type())
        parser.parse_pre_request_script(script_node, source, c)
        assert.same({
            foo = "bar",
        }, c.lv)
    end)

    it("parse response-redirect syntax", function()
        local source = "GET localhost:3000\n\n>> path/to/file.json\n"
        local _, tree = utils.ts_parse_source(source)
        local node = assert(tree:root():child(0))
        local req = assert(parser.parse(node, source))
        assert.same(1, #req.handlers)
    end)

    -- TODO: update this testcase
    --   it("create context from source", function()
    --     local source = [[
    -- @foo=bar
    -- @bar=1234
    -- @baz={{foo}} adsf
    -- ]]
    --     local ctx = parser.create_context(source)
    --     assert.same({
    --       foo = "bar",
    --       bar = "1234",
    --       baz = "bar adsf",
    --     }, ctx.vars)
    --   end)
end)
