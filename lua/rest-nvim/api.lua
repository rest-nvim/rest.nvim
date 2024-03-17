---@mod rest-nvim.api rest.nvim Lua API
---
---@brief [[
---
---The Lua API for rest.nvim
---Intended for use by third-party modules that extend its functionalities.
---
---@brief ]]

local api = {}

local keybinds = require("rest-nvim.keybinds")
local autocmds = require("rest-nvim.autocmds")
local commands = require("rest-nvim.commands")

---rest.nvim API version, equals to the current rest.nvim version. Meant to be used by modules later
---@type string
---@see vim.version
api.VERSION = "2.0.0"

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
  autocmds.register_autocmd(events, cb, description)
end

---Register a new `:Rest` subcommand
---@param name string The name of the subcommand to register
---@param cmd RestCmd
function api.register_rest_subcommand(name, cmd)
  commands.register_subcommand(name, cmd)
end

---Register a new keybinding
---@see vim.keymap.set
---
---@param mode string Keybind mode
---@param lhs string Keybind trigger
---@param cmd string Command to be run
---@param opts table Keybind options
function api.register_rest_keybind(mode, lhs, cmd, opts)
  keybinds.register_keybind(mode, lhs, cmd, opts)
end

---Execute all the pre-request hooks, functions that are meant to run before executing a request
---
---This function is called automatically during the execution of the requests, invoking it again could cause inconveniences
---@see vim.api.nvim_exec_autocmds
---@package
function api.exec_pre_request_hooks()
  vim.api.nvim_exec_autocmds("User", {
    pattern = "RestStartRequest",
    modeline = false,
  })
end

---Execute all the post-request hooks, functions that are meant to run after executing a request
---
---This function is called automatically during the execution of the requests, invoking it again could cause inconveniences
---@see vim.api.nvim_exec_autocmds
---@package
function api.exec_post_request_hooks()
  vim.api.nvim_exec_autocmds("User", {
    pattern = "RestStopRequest",
    modeline = false,
  })
end

return api
