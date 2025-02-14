-- HACK: this file isn't really needed for release because rest.nvim uses
-- luarocks-tags-relase github action for actual relaeses, but it is here to be
-- used for local testing

---@diagnostic disable: lowercase-global
local MAJOR, REV = "scm", "-1"
rockspec_format = "3.0"
package = "rest.nvim"
version = MAJOR .. REV

description = {
  summary = "A fast and asynchronous Neovim HTTP client written in Lua",
  labels = { "neovim", "rest" },
  detailed = [[
    A very fast, powerful, extensible and asynchronous Neovim HTTP client written in Lua.
    rest.nvim by default makes use of its own `curl` wrapper to make requests and a tree-sitter parser to parse http files.
  ]],
  homepage = "https://github.com/rest-nvim/rest.nvim",
  license = "GPLv3",
}

dependencies = {
  "lua >= 5.1, < 5.4",
  "nvim-nio",
  "mimetypes",
  "xml2lua",
  "fidget.nvim",
  "base64",
  "tree-sitter-http == 0.0.35",
}

test_dependencies = {
  "nlua",
}

source = {
  url = "http://github.com/rest-nvim/rest.nvim/archive/" .. MAJOR .. ".zip",
  dir = "rest.nvim-" .. MAJOR,
}

if MAJOR == "scm" then
  source = {
    url = "git://github.com/rest-nvim/rest.nvim",
  }
end

build = {
  type = "builtin",
  copy_directories = {
    "doc",
    "plugin",
    "ftdetect",
    "ftplugin",
    "queries",
    "syntax",
  }
}
