---@mod rest-nvim rest.nvim
---
---@brief [[
---
--- A fast and asynchronous Neovim HTTP client written in Lua
---
---@brief ]]

local rest = {}

local config = require("rest-nvim.config")
local autocmds = require("rest-nvim.autocmds")

---Set up rest.nvim
---@param user_configs RestConfig User configurations
function rest.setup(user_configs)
  -- Set up rest.nvim configurations
  _G._rest_nvim = config.set(user_configs or {})

  -- Set up rest.nvim autocommands and commands
  autocmds.setup()
end

return rest
