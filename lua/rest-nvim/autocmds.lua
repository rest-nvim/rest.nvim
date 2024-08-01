---@mod rest-nvim.autocmds rest.nvim autocommands
---
---@brief [[
---
--- rest.nvim autocommands
---
---@brief ]]

local autocmds = {}

local result = require("rest-nvim.result")
local config = require("rest-nvim.config")
local result_help = require("rest-nvim.result.help")

---Set up Rest autocommands group
function autocmds.setup()
  local rest_nvim_augroup = vim.api.nvim_create_augroup("Rest", {})
  local keybinds = config.result.keybinds

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = rest_nvim_augroup,
    pattern = "rest_nvim_results",
    callback = function(args)
      vim.keymap.set("n", keybinds.prev, function()
        result.cycle_pane(-1)
      end, {
        desc = "Go to previous winbar pane",
        buffer = args.buf,
      })
      vim.keymap.set("n", keybinds.next, function()
        result.cycle_pane(1)
      end, {
        desc = "Go to next winbar pane",
        buffer = args.buf,
      })
      vim.keymap.set("n", "?", result_help.open, {
        desc = "Open rest.nvim request results help window",
        buffer = args.buf,
      })
      vim.keymap.set("n", "q", function()
        vim.api.nvim_buf_delete(args.buf, { unload = true })
      end, { desc = "Close rest.nvim results buffer", buffer = args.buf })
    end,
    desc = "Set up rest.nvim results buffer keybinds",
  })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    group = rest_nvim_augroup,
    pattern = "rest_winbar_help",
    callback = function(args)
      vim.keymap.set("n", "q", result_help.close, {
        desc = "Close rest.nvim request results help window",
        buffer = args.buf,
      })
    end,
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
