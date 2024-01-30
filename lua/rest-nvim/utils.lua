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

--- Default transformers for statistics
local transform = {
  ---Transform `time` into a readable typed time (e.g. 200ms)
  ---@param time string
  ---@return string
  time = function(time)
    time = tonumber(time)

    if time >= 60 then
      time = string.format("%.2f", time / 60)

      return time .. " min"
    end

    local units = { "s", "ms", "µs", "ns" }
    local unit = 1

    while time < 1 and unit <= #units do
      time = time * 1000
      unit = unit + 1
    end

    time = string.format("%.2f", time)

    return time .. " " .. units[unit]
  end,

  ---Transform `bytes` into another bigger size type if needed
  ---@param bytes string
  ---@return string
  size = function(bytes)
    ---@diagnostic disable-next-line cast-local-type
    bytes = tonumber(bytes)

    local units = { "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB" }
    local unit = 1

    while bytes >= 1024 and unit <= #units do
      ---@diagnostic disable-next-line cast-local-type
      bytes = bytes / 1024
      unit = unit + 1
    end

    bytes = string.format("%.2f", bytes)

    return bytes .. " " .. units[unit]
  end,
}

utils.transform_time = transform.time
utils.transform_size = transform.size

return utils
