---@mod rest-nvim.autocmds rest.nvim autocommands
---
---@brief [[
---
--- rest.nvim autocommands
---
---@brief ]]

local autocmds = {}

local commands = require("rest-nvim.commands")

---Set up Rest autocommands group and set `:Rest` command on `*.http` files
function autocmds.setup()
  local rest_nvim_augroup = vim.api.nvim_create_augroup("Rest", {})
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = rest_nvim_augroup,
    pattern = "*.http",
    callback = function(args)
      commands.init(args.buf)
    end,
    desc = "Set up rest.nvim commands",
  })
end

---Register a new autocommand in the `Rest` augroup
---@see vim.api.nvim_create_augroup
---@see vim.api.nvim_create_autocmd
---
---@param events string[] Autocommand events, see `:h events`
---@param cb string|fun(args: table) Autocommand lua callback, runs a Vimscript command instead if it is a `string`
---@param description string Autocommand description
---@package
function autocmds.register_autocmd(events, cb, description)
  vim.validate({
    events = { events, "table" },
    cb = { cb, { "function", "string" } },
    description = { description, "string" },
  })

  local autocmd_opts = {
    group = "Rest",
    pattern = "*.http",
    desc = description,
  }

  if type(cb) == "function" then
    autocmd_opts = vim.tbl_deep_extend("force", autocmd_opts, {
      callback = cb,
    })
  elseif type(cb) == "string" then
    autocmd_opts = vim.tbl_deep_extend("force", autocmd_opts, {
      command = cb,
    })
  end

  vim.api.nvim_create_autocmd(events, autocmd_opts)
end

return autocmds
