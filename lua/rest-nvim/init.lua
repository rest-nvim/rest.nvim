---@mod rest-nvim rest.nvim
---
---@brief [[
---
--- A fast and asynchronous Neovim HTTP client written in Lua
---
---@brief ]]

local rest = {}

local config = require("rest-nvim.config")
local keybinds = require("rest-nvim.keybinds")
local autocmds = require("rest-nvim.autocmds")

---Set up rest.nvim
---@param user_configs RestConfig User configurations
function rest.setup(user_configs)
  -- Set up rest.nvim configurations
  _G._rest_nvim = config.set(user_configs or {})

  -- Set up rest.nvim keybinds
  keybinds.apply()

  -- Set up rest.nvim autocommands and commands
  autocmds.setup()

  -- Set up tree-sitter HTTP parser branch
  -- NOTE: remove this piece of code once rest.nvim v2 has been pushed
  --       and tree-sitter-http `next` branch has been merged
  local ok, treesitter_parsers = pcall(require, "nvim-treesitter.parsers")
  if ok then
    local parser_config = treesitter_parsers.get_parser_configs()

    parser_config.http = vim.tbl_deep_extend("force", parser_config.http, {
      install_info = { branch = "next" },
    })
  end
end

return rest
