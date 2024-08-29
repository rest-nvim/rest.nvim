---@module 'luassert'

local utils = require("rest-nvim.utils")

local function open(path)
    vim.cmd.edit(path)
    return 0
end

describe("tree-sitter utils", function()
    local source = open("spec/examples/script/post_request_script.http")
    it("ts_parse_source", function()
        local _, tree = utils.ts_parse_source(source)
        local url_node = assert(tree:root():child(0):field("request")[1]:field("url")[1])
        assert.same("target_url", url_node:type())
        assert.is_false(tree:root():has_error())
    end)
    it("ts_find", function()
        local start_node = assert(vim.treesitter.get_node({pos={4, 3}, lang="http"}))
        local script_node = assert(utils.ts_find(start_node, "script"))
        assert.same("script", script_node:type())
        local sr, sc, er, ec = script_node:range()
        assert.same({ 4, 2, 7, 2 }, { sr, sc, er, ec })
    end)
    it("ts_upper_node", function()
        local start_node = assert(vim.treesitter.get_node({pos={4, 3}, lang="http"}))
        local comment_node = assert(utils.ts_upper_node(start_node))
        assert.same("comment", comment_node:type())
    end)
end)

describe("gq_lines", function()
    it("plain text", function()
        local lines = {
            "Lorem",
            "ipsum dolor sit amet, consectetur adipiscing elit. Nulla id nisl ut sapien ullamcorper congue non in ipsum",
            ". Phasellus efficitur metus lectus, sed placerat eros mollis varius. Praesent egestas sapien vel auctor egestas. Praesent ac lacus consequat, rhoncus libero et, ultricies urna. Maecenas vitae tortor ut mi convallis volutpat. Nam.",
        }
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "text",
            callback = function(ev)
                vim.bo[ev.buf].formatprg = "fmt"
            end,
        })
        assert.same({
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla id nisl",
            "ut sapien ullamcorper congue non in ipsum . Phasellus efficitur metus",
            "lectus, sed placerat eros mollis varius. Praesent egestas sapien vel",
            "auctor egestas. Praesent ac lacus consequat, rhoncus libero et, ultricies",
            "urna. Maecenas vitae tortor ut mi convallis volutpat. Nam.",
        }, utils.gq_lines(lines, "text"))
    end)
    it("json with jq", function()
        local lines = {
            " {",
            '         "foo"    : 123      }',
        }
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "json",
            callback = function(ev)
                vim.bo[ev.buf].formatprg = "jq --indent 4"
            end,
        })
        assert.same({
            "{",
            '    "foo": 123',
            "}",
        }, utils.gq_lines(lines, "json"))
    end)
    it("xml with xmlformat#Format()", function()
        local lines = {
            "<note>",
            "<to>User</to>",
            "<from>Bob</from>",
            "<heading>Reminder</heading>",
            "<body>Don't forget to complete your tasks today!</body>",
            "</note>",
        }
        assert.same({
            "<note>",
            "        <to>User</to>",
            "        <from>Bob</from>",
            "        <heading>Reminder</heading>",
            "        <body>Don't forget to complete your tasks today!</body>",
            "</note>",
        }, utils.gq_lines(lines, "xml"))
    end)
end)
