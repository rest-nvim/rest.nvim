local test_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local rest_nvim_dir = vim.fn.fnamemodify(test_dir, ":h")

vim.opt.rtp:prepend(vim.fs.normalize("/home/ubuntu/projects/tree-sitter-http"))
local parser_dir = "$HOME/.cache/tree-sitter/lib/http.so"
if vim.fn.has("macunix") == 1 then
    parser_dir = "$HOME/Library/Caches/tree-sitter/lib/http.dylib"
end
vim.treesitter.language.add("http", { path = vim.fs.normalize(parser_dir) })
if not vim.treesitter.language.get_lang("http") then
    vim.treesitter.language.register("http", "http")
end
vim.opt.runtimepath:append(rest_nvim_dir)
vim.cmd("runtime! ftplugin.vim")
vim.cmd("runtime! plugin/**/*.{vim,lua}")
vim.cmd("runtime! ftdetect/*.{vim,lua}")
vim.cmd("runtime! filetype.lua")
vim.g.rest_nvim = {
    _log_level = vim.log.levels.INFO,
    request = {
        hooks = {
            user_agent = "",
        },
    },
    cookies = {
        path = "/tmp/rest-nvim.cookies",
    },
}
---@diagnostic disable-next-line: undefined-field
vim.uv.fs_unlink(vim.g.rest_nvim.cookies.path)
