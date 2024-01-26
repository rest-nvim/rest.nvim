---@mod rest-nvim.utils rest.nvim utilities
---
---@brief [[
---
--- rest.nvim utility functions
---
---@brief ]]

local utils = {}

-- NOTE: vim.loop has been renamed to vim.uv in Neovim >= 0.10 and will be removed later
local uv = vim.uv or vim.loop

---Check if a file exists in the given `path`
---@param path string file path
---@return boolean
function utils.file_exists(path)
  local fd = uv.fs_open(path, "r", 438)
  if fd then
    uv.fs_close(fd)
    return true
  end

  return false
end

return utils
