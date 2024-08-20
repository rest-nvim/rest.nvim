---@mod rest-nvim rest.nvim
---
---@brief [[
---
--- A fast and asynchronous Neovim HTTP client written in Lua
---
---@brief ]]

---@toc rocks-contents

local rest = {}

---@deprecated use `vim.g.rest_nvim` instead
---Set up rest.nvim
---This api does nothing but set `vim.g.rest_nvim` to `user_configs`
---@param user_configs? rest.Opts User configurations
function rest.setup(user_configs)
  -- Set up rest.nvim configurations
  vim.g.rest_nvim = user_configs or {}
end

return rest
