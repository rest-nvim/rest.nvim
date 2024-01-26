---@mod rest-nvim.api rest.nvim Lua API
---
---@brief [[
---
---The Lua API for rest.nvim
---Intended for use by third-party modules that extend its functionalities.
---
---@brief ]]

local api = {}

local autocmds = require("rest-nvim.autocmds")
local commands = require("rest-nvim.commands")

---Register a new autocommand in the `Rest` augroup
---@see vim.api.nvim_create_augroup
---@see vim.api.nvim_create_autocmd
---
---@param events string[] Autocommand events, see `:h events`
---@param cb string|fun(args: table) Autocommand lua callback, runs a Vimscript command instead if it is a `string`
---@param description string Autocommand description
function api.register_rest_autocmd(events, cb, description)
  autocmds.register_autocmd(events, cb, description)
end

---Register a new `:Rest` subcommand
---@param name string The name of the subcommand to register
---@param cmd RestCmd
function api.register_rest_subcommand(name, cmd)
  commands.register_subcommand(name, cmd)
end

return api
