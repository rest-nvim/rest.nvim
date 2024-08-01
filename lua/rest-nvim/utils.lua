---@mod rest-nvim.utils rest.nvim utilities
---
---@brief [[
---
--- rest.nvim utility functions
---
---@brief ]]

local logger = require("rest-nvim.logger")
-- local config = require("rest-nvim.config")

local utils = {}

-- NOTE: vim.loop has been renamed to vim.uv in Neovim >= 0.10 and will be removed later
local uv = vim.uv or vim.loop

---Encodes a string into its escaped hexadecimal representation
---taken from Lua Socket and added underscore to ignore
---@param str string Binary string to be encoded
---@return string
function utils.escape(str)
  local encoded = string.gsub(str, "([^A-Za-z0-9_])", function(c)
    return string.format("%%%02x", string.byte(c))
  end)

  return encoded
end

---Check if a file exists in the given `path`
---@param path string file path
---@return boolean
function utils.file_exists(path)
  ---@diagnostic disable-next-line undefined-field
  local fd = uv.fs_open(path, "r", 438)
  if fd then
    ---@diagnostic disable-next-line undefined-field
    uv.fs_close(fd)
    return true
  end

  return false
end

---Read a file if it exists
---@param path string file path
---@return string
function utils.read_file(path)
  ---@type string|nil
  local content
  if utils.file_exists(path) then
    ---@diagnostic disable-next-line undefined-field
    local file = uv.fs_open(path, "r", 438)
    ---@diagnostic disable-next-line undefined-field
    local stat = uv.fs_fstat(file)
    ---@diagnostic disable-next-line undefined-field
    content = uv.fs_read(file, stat.size, 0)
    ---@diagnostic disable-next-line undefined-field
    uv.fs_close(file)
  else
    ---@diagnostic disable-next-line need-check-nil
    logger.error("Failed to read file '" .. path .. "'")
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

---@param bufnr number
---@param node TSNode
---@param ns number
function utils.ts_highlight_node(bufnr, node, ns)
  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local highlight = require("rest-nvim.config").highlight
  local higroup = "IncSearch"
  local s_row, s_col = node:start()
  local e_row, e_col = node:end_()
  -- don't try to highlight over the last line
  if e_col == 0 then
    e_row = e_row - 1
    e_col = -1
  end
  vim.highlight.range(
    bufnr,
    ns,
    higroup,
    { s_row, s_col },
    { e_row, e_col },
    { regtype = "v" }
  )

  -- Clear buffer highlights again after timeout
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
  end, highlight.timeout)
end

---@param source string|integer
---@return vim.treesitter.LanguageTree
---@return TSTree
function utils.ts_parse_source(source)
  local ts_parser
  if type(source) == "string" then
    ts_parser = vim.treesitter.get_string_parser(source, "http")
  else
    ts_parser = vim.treesitter.get_parser(source, "http")
  end
  return ts_parser, assert(ts_parser:parse(false)[1])
end

---@param node TSNode
---@param type string
---@return TSNode?
function utils.ts_find(node, type)
  if node:type() == type then
    return node
  end
  local parent = node:parent()
  if parent then
    return utils.ts_find(parent, type)
  end
  return nil
end

---@param node TSNode
---@param expected_type string
---@return table
function utils.ts_node_spec(node, expected_type)
  return {
    node,
    function (n)
      return n:type() == expected_type
    end,
    "("..expected_type..") TSNode",
  }
end

---Create error log for TSNode that has a syntax error
---@param node TSNode Tree-sitter node
---@return string
function utils.ts_node_error_log(node)
  local s_row, s_col = node:start()
  local e_row, e_col = node:end_()
  local range = "["

  if s_row == e_row then
    range = range .. s_row .. ":" .. s_col .. " - " .. e_col
  else
    range = range .. s_row .. ":" .. s_col .. " - " .. e_row .. ":" .. e_col
  end
  range = range .. "]"
  return "The tree-sitter node at the range " .. range .. " has a syntax error and cannot be parsed"
end

return utils
