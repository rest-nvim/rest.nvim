---@mod rest-nvim rest.nvim
---
---@brief [[
---
--- A fast and asynchronous Neovim HTTP client written in Lua
---
---@brief ]]

local rest = {}

---Set up rest.nvim
---@param user_configs rest.Opts User configurations
function rest.setup(user_configs)
  -- Set up rest.nvim configurations
  vim.g.rest_nvim = user_configs
  require("rest-nvim.config")
end

return rest
