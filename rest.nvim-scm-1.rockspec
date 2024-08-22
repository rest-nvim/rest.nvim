---@diagnostic disable: lowercase-global
local MAJOR, REV = "scm", "-1"
rockspec_format = "3.0"
package = "rest.nvim"
version = MAJOR .. REV

description = {
  summary = "A fast and asynchronous Neovim HTTP client written in Lua",
  labels = { "neovim", "rest" },
  detailed = [[
    rest.nvim makes use of Lua cURL bindings to make HTTP requests so you don't have to leave Neovim to test your back-end codebase!
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
  "tree-sitter-http >= scm",
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
    branch = "dev",
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
  }
}
