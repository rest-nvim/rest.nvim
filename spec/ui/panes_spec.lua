---@module 'luassert'

require("spec.minimal_init")

local paneui = require("rest-nvim.ui.panes")
local utils = require("rest-nvim.utils")

---@type rest.ui.panes.PaneOpts[]
local panes = {
    {
        name = "First",
        render = function(self)
            vim.b[self.bufnr].name = "first"
            return true
        end,
    },
    {
        name = "Second",
        render = function(self)
            vim.b[self.bufnr].name = "second"
        end,
    },
}

local group = paneui.create_pane_group("test_panes_1", panes, {
    on_init = function(self)
        utils.nvim_lazy_set_wo(self.bufnr, "winbar", "this-is-a-winbar")
    end,
})

describe("ui.panes", function()
    it("all panes are rendered", function()
        -- nothing happens before entering the pane
        assert.not_same("first", vim.b.name)
        assert.not_same("second", vim.b.name)
        assert.not_same("this-is-a-winbar", vim.api.nvim_get_option_value("winbar", { scope = "local" }))

        -- enter the pane
        group:enter(0)
        assert.same("first", vim.b.name)
        assert.same("this-is-a-winbar", vim.api.nvim_get_option_value("winbar", { scope = "local" }))

        -- cycle to second pane
        group:cycle(1)
        assert.same("second", vim.b.name)
        assert.same("this-is-a-winbar", vim.api.nvim_get_option_value("winbar", { scope = "local" }))

        -- cycle back to first pane
        group:cycle(3)
        assert.same("first", vim.b.name)
        assert.same("this-is-a-winbar", vim.api.nvim_get_option_value("winbar", { scope = "local" }))

        -- go back to original non-pane buffer
        vim.cmd.buffer(1)
        assert.not_same("first", vim.b.name)
        assert.not_same("second", vim.b.name)
        assert.not_same("this-is-a-winbar", vim.api.nvim_get_option_value("winbar", { scope = "local" }))
    end)
    it("initialize the buffer back after unloaded", function()
        assert.same(1, vim.api.nvim_get_current_buf())
        group:enter(0)
        local pane_buf = vim.api.nvim_get_current_buf()
        assert.not_same(1, pane_buf)
        vim.cmd.bdelete()
        assert.same(1, vim.api.nvim_get_current_buf())
        group:enter(0)
        assert.same(pane_buf, vim.api.nvim_get_current_buf())
        assert.same("first", vim.b.name)
        assert.same("this-is-a-winbar", vim.api.nvim_get_option_value("winbar", { scope = "local" }))
    end)
end)
