---@mod rest-nvim.api rest.nvim Lua API
---
---@brief [[
---
---The Lua API for rest.nvim
---Intended for use by third-party modules that extend its functionalities.
---
---@brief ]]

local api = {}

-- stylua: ignore start
local autocmds = function() return require("rest-nvim.client") end
local commands = function() return require("rest-nvim.client") end
local client = function() return require("rest-nvim.client") end
-- stylua: ignore end

---rest.nvim API version, equals to the current rest.nvim version. Meant to be used by modules later
---@type string
---@see vim.version
api.VERSION = "3.8.0" -- x-release-please-version

---rest.nvim namespace used for buffer highlights
---@type number
---@see vim.api.nvim_create_namespace
api.namespace = vim.api.nvim_create_namespace("rest-nvim")

---Register a new autocommand in the `Rest` augroup
---@see vim.api.nvim_create_augroup
---@see vim.api.nvim_create_autocmd
---
---@param events string[] Autocommand events, see `:h events`
---@param cb string|fun(args: table) Autocommand lua callback, runs a Vimscript command instead if it is a `string`
---@param description string Autocommand description
function api.register_rest_autocmd(events, cb, description)
    ---@diagnostic disable-next-line: invisible
    autocmds().register_autocmd(events, cb, description)
end

---Register a new `:Rest` subcommand
---@param name string The name of the subcommand to register
---@param cmd RestCmd
function api.register_rest_subcommand(name, cmd)
    ---@diagnostic disable-next-line: invisible
    commands().register_subcommand(name, cmd)
end

function api.register_rest_client(c)
    client().register_client(c)
end

return api
