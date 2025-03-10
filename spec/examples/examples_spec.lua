---@module 'luassert'

require("spec.minimal_init")

local parser = require("rest-nvim.parser")
local utils = require("rest-nvim.utils")
local Context = require("rest-nvim.context").Context

local function open(path)
    vim.cmd.edit(path)
    return 0
end

describe("multi-line-url", function()
    it("line breaks should be ignored", function()
        local source = open("spec/examples/basic_get.http")
        local _, tree = utils.ts_parse_source(source)
        local req_node = assert(tree:root():child(2))
        local req = parser.parse(req_node, source)
        assert.not_nil(req)
        ---@cast req rest.Request
        assert.same("http://example.com:8080/api/html/get?id=123&value=content", req.url)
    end)
end)

describe("url without host", function()
    local source = open("spec/examples/url_without_host.http")
    local req_nodes = parser.get_all_request_nodes(source)
    assert.same(4, #req_nodes)
    it("host with non-secure port", function()
        local req = parser.parse(req_nodes[1], source)
        assert.not_nil(req)
        ---@cast req rest.Request
        assert.same("http://example.com:8080/api", req.url)
    end)
    it("host with secure port", function()
        local req = parser.parse(req_nodes[2], source)
        assert.not_nil(req)
        ---@cast req rest.Request
        assert.same("https://example.com:443/api", req.url)
    end)
    it("host with protocol", function()
        local req = parser.parse(req_nodes[3], source)
        assert.not_nil(req)
        ---@cast req rest.Request
        assert.same("http://example.com/api", req.url)
    end)
    it("host without protocol", function()
        local req = parser.parse(req_nodes[4], source)
        assert.not_nil(req)
        ---@cast req rest.Request
        assert.same("https://example.com/api", req.url)
    end)
end)

describe("in-place variables", function()
    it("parse context sequentially", function()
        local source = open("spec/examples/variables/in_place_variables.http")
        local ctx = Context:new()
        parser.eval_context(source, ctx, -1)
        assert.same("", ctx:resolve("myhost"))
        parser.eval_context(source, ctx, 0)
        assert.same("", ctx:resolve("myhost"))
        parser.eval_context(source, ctx, 1)
        assert.same("example.org", ctx:resolve("myhost"))
        parser.eval_context(source, ctx, 2)
        assert.same("example.org", ctx:resolve("myhost"))
        parser.eval_context(source, ctx, 12)
        assert.same("example.net", ctx:resolve("myhost"))
    end)
    describe("evaluate context across multiple requests", function()
        local source = open("spec/examples/variables/in_place_variables.http")
        local req_nodes = parser.get_all_request_nodes(source)
        assert(#req_nodes >= 3)
        local ctx = Context:new()
        it("example 1", function()
            local req1 = assert(parser.parse(req_nodes[1], source, ctx))
            ---@cast req1 rest.Request
            assert.same("example.org/users", req1.url)
        end)
        it("example 2", function()
            local req2 = assert(parser.parse(req_nodes[2], source, ctx))
            assert.same("example.net/users", req2.url)
        end)
        it("example 3", function()
            local req3 = assert(parser.parse(req_nodes[3], source, ctx))
            assert.same("example.net/stats", req3.url)
        end)
    end)
end)

describe("pre-request script", function()
    local source = open("spec/examples/script/pre_request_script.http")
    local req_nodes = parser.get_all_request_nodes(source)
    assert.same(2, #req_nodes)
    local ctx = Context:new()
    it("set local variable from pre-request script", function()
        local req1 = assert(parser.parse(req_nodes[1], source, ctx))
        assert.same("https://jsonplaceholder.typicode.com/posts/3", req1.url)
    end)
    it("local variables don't affect other requests", function()
        local req2 = assert(parser.parse(req_nodes[2], source, ctx))
        assert.same("https://jsonplaceholder.typicode.com/posts/", req2.url)
    end)
end)

describe("builtin request hooks", function()
    describe("set_content_type", function()
        it("with external body", function()
            local source = open("spec/examples/request_body/external_body.http")
            local _, tree = utils.ts_parse_source(source)
            local req_node = assert(tree:root():child(1))
            local req = assert(parser.parse(req_node, source))
            _G.rest_request = req
            vim.api.nvim_exec_autocmds("User", {
                pattern = { "RestRequest", "RestRequestPre" },
            })
            _G.rest_request = nil
            assert.same({ "application/json" }, req.headers["content-type"])
        end)
    end)
    ---@return rest.Request
    local function sample_request(opts)
        return vim.tbl_deep_extend("keep", opts, {
            method = "GET",
            url = "https://example.com",
            headers = {},
            cookies = {},
            handlers = {},
        })
    end
    describe("interpret_basic_auth", function()
        it("with valid vscode style token", function()
            local req = sample_request({
                headers = {
                    ["authorization"] = { "Basic username:password" },
                },
            })
            _G.rest_request = req
            vim.api.nvim_exec_autocmds("User", {
                pattern = { "RestRequest", "RestRequestPre" },
            })
            _G.rest_request = nil
            assert.same({ "Basic dXNlcm5hbWU6cGFzc3dvcmQ=" }, req.headers["authorization"])
        end)
        it("with valid intellij style token", function()
            local req = sample_request({
                headers = {
                    ["authorization"] = { "Basic username password" },
                },
            })
            _G.rest_request = req
            vim.api.nvim_exec_autocmds("User", {
                pattern = { "RestRequest", "RestRequestPre" },
            })
            _G.rest_request = nil
            assert.same({ "Basic dXNlcm5hbWU6cGFzc3dvcmQ=" }, req.headers["authorization"])
        end)
    end)
end)
it("make sure md5 work", function()
    local md5 = require("md5")
    local md5sum = md5.sumhexa
    assert.same("9236657b478ea807fdfa275d24990843", md5sum("qwer:asdf"))
    -- TODO: implement digest auth with https://github.com/catwell/lua-http-digest/blob/master/http-digest.lua
end)
