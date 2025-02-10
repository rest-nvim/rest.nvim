vim.opt.runtimepath:append(vim.env.TREE_SITTER_HTTP_PLUGIN_DIR)
vim.opt.runtimepath:append(vim.env.REST_NVIM_PLUGIN_DIR)
vim.cmd("runtime! ftplugin.vim")
vim.cmd("runtime! ftdetect/*.{vim,lua}")
vim.cmd("runtime! filetype.lua")
vim.cmd("runtime! plugin/**/*.{vim,lua}")
local clipboard = {}
local function copy(lines)
    clipboard = lines
end
local function paste()
    return clipboard
end
vim.g.clipboard = {
    name = "bolt",
    copy = {
        ["+"] = copy,
        ["*"] = copy,
    },
    paste = {
        ["+"] = paste,
        ["*"] = paste,
    },
}
vim.g.rest_nvim = {
    _log_level = vim.log.levels.INFO,
    request = {
        hooks = {
            user_agent = "",
        },
    },
    cookies = {
        path = vim.fn.tempname(),
    },
}
---@diagnostic disable-next-line: undefined-field
vim.uv.fs_unlink(vim.g.rest_nvim.cookies.path)
