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

---Read a file if it exists
---@param path string file path
---@return string
function utils.read_file(path)
  local logger = _G._rest_nvim.logger

  ---@type string|uv_fs_t|nil
  local content
  if utils.file_exists(path) then
    local file = uv.fs_open(path, "r", 438)
    ---@cast file number
    local stat = uv.fs_fstat(file)
    ---@cast stat uv.aliases.fs_stat_table
    content = uv.fs_read(file, stat.size, 0)
    ---@cast content string
    uv.fs_close(file)
  else
    ---@diagnostic disable-next-line need-check-nil
    logger:error("Failed to read file '" .. path .. "'")
    return ""
  end

  ---@cast content string
  return content
end

--- Default transformers for statistics
local transform = {
  ---Transform `time` into a readable typed time (e.g. 200ms)
  ---@param time string
  ---@return string
  time = function(time)
    ---@diagnostic disable-next-line cast-local-type
    time = tonumber(time)

    if time >= 60 then
      time = string.format("%.2f", time / 60)

      return time .. " min"
    end

    local units = { "s", "ms", "µs", "ns" }
    local unit = 1

    while time < 1 and unit <= #units do
      ---@diagnostic disable-next-line cast-local-type
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

---Highlight a request
---@param bufnr number Buffer handler ID
---@param start number Request tree-sitter node start
---@param end_ number Request tree-sitter node end
---@param ns number rest.nvim Neovim namespace
function utils.highlight(bufnr, start, end_, ns)
  local highlight = _G._rest_nvim.highlight
  local higroup = "IncSearch"
  local timeout = highlight.timeout

  -- Clear buffer highlights
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  -- Highlight request
  vim.highlight.range(
    bufnr,
    ns,
    higroup,
    { start, 0 },
    { end_, string.len(vim.fn.getline(end_)) },
    { regtype = "c", inclusive = false }
  )

  -- Clear buffer highlights again after timeout
  vim.defer_fn(function()
    vim.notify("Cleaning highlights")
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
  end, timeout)
end

return utils
