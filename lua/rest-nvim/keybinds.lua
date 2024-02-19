---@mod rest-nvim.autocmds rest.nvim autocommands
---
---@brief [[
---
--- rest.nvim autocommands
---
---@brief ]]

local keybinds = {}

---Apply user-defined keybinds in the rest.nvim configuration
function keybinds.apply()
  local keybindings = _G._rest_nvim.keybinds
  for _, keybind in ipairs(keybindings) do
    local lhs = keybind[1]
    local cmd = keybind[2]
    local desc = keybind[3]

    vim.validate({
      lhs = { lhs, "string" },
      cmd = { cmd, "string" },
      desc = { desc, "string" },
    })

    vim.keymap.set("n", lhs, cmd, { desc = desc })
  end
end

---Register a new keybinding
---@see vim.keymap.set
---
---@param mode string Keybind mode
---@param lhs string Keybind trigger
---@param cmd string Command to be run
---@param opts table Keybind options
---@package
function keybinds.register_keybind(mode, lhs, cmd, opts)
  vim.validate({
    mode = { mode, "string" },
    lhs = { lhs, "string" },
    cmd = { cmd, "string" },
    opts = { opts, "table" },
  })

  vim.keymap.set(mode, lhs, cmd, opts)
end

return keybinds
