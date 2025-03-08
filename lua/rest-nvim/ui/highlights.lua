---@mod rest-nvim.highlight-groups rest.nvim highlight groups
---
---@brief [[
---
--- rest.nvim result UI implementation
--- Highlight Group      Default                          Description
--- -------------------- -------------------------------- --------------------
--- RestText             Comment                          winbar text
--- RestPaneTitleNC      Statement                        winbar text in non-current pane
--- RestPaneTitle        Statement + bold + underline     winbar Text in current pane
---
---@brief ]]

---Get the foreground value of a highlighting group
---@param name string Highlighting group name
---@return string
local function get_hl_group_fg(name)
    -- This will still error out if the highlight doesn't exist
    return string.format("#%06X", vim.api.nvim_get_hl(0, { name = name, link = false }).fg)
end

vim.api.nvim_set_hl(0, "RestText", { fg = get_hl_group_fg("Comment"), default = true })
vim.api.nvim_set_hl(0, "RestPaneTitleNC", { fg = get_hl_group_fg("Statement"), default = true })
vim.api.nvim_set_hl(0, "RestPaneTitle", {
    fg = get_hl_group_fg("Statement"),
    bold = true,
    underline = true,
    default = true,
})

---@comment HACK: to generate documnet with vimcats
local M = {}
return M
