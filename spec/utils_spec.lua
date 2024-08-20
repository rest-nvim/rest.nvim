---@module 'luassert'

local utils = require("rest-nvim.utils")

describe("tree-sitter utils", function()
    local source = [[
http://localhost:8000

# @lang=lua
> {%
local json = vim.json.decode(response.body)
json.data = "overwritten"
response.body = vim.json.encode(json)
%}
]]
    local script_node
    it("ts_parse_source", function()
        local _, tree = utils.ts_parse_source(source)
        script_node = assert(tree:root():child(0):child(1))
        assert.same("res_handler_script", script_node:type())
    end)
    it("ts_find", function()
        local section_node = assert(utils.ts_find(script_node, "section"))
        assert.same("section", section_node:type())
        local sr, sc, er, ec = section_node:range()
        assert.same({ 0, 0, 8, 0 }, { sr, sc, er, ec })
    end)
    it("ts_upper_node", function()
        local comment_node = assert(utils.ts_upper_node(script_node))
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
        assert.same({
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nulla id nisl ut",
            "sapien ullamcorper congue non in ipsum . Phasellus efficitur metus lectus, sed",
            "placerat eros mollis varius. Praesent egestas sapien vel auctor egestas.",
            "Praesent ac lacus consequat, rhoncus libero et, ultricies urna. Maecenas vitae",
            "tortor ut mi convallis volutpat. Nam.",
        }, utils.gq_lines(lines, ""))
    end)
end)
