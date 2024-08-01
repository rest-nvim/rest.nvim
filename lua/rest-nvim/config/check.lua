---@mod rest-nvim.config.check rest.nvim config validation
---
---@brief [[
---
--- rest.nvim config validation (internal)
---
---@brief ]]

local check = {}

---@param tbl table The table to validate
---@see vim.validate
---@return boolean is_valid
---@return string|nil error_message
local function validate(tbl)
  local ok, err = pcall(vim.validate, tbl)
  return ok or false, "Invalid config" .. (err and ": " .. err or "")
end

---Validates the configuration
---@param cfg RestConfig
---@return boolean is_valid
---@return string|nil error_message
function check.validate(cfg)
  local ok, err = validate({
    env_pattern = { cfg.env_pattern, "string" },
    encode_url = { cfg.encode_url, "boolean" },
    skip_ssl_verification = { cfg.skip_ssl_verification, "boolean" },
    custom_dynamic_variables = { cfg.custom_dynamic_variables, "table" },
    -- RestConfigResult
    result = { cfg.result, "table" },
    -- RestConfigResultWindow
    window = { cfg.result.window, "table" },
    horizontal = { cfg.result.window.horizontal, "boolean" },
    enter = { cfg.result.window.enter, "boolean" },
    -- RestConfigResultBehavior
    behavior = { cfg.result.behavior, "table" },
    decode_url = { cfg.result.behavior.decode_url, "boolean" },
    -- RestConfigResultStats
    statistics = { cfg.result.behavior.statistics, "table" },
    statistics_enable = { cfg.result.behavior.statistics.enable, "boolean" },
    stats = { cfg.result.behavior.statistics.stats, "table" },
    -- RestConfigResultFormatters
    formatters = { cfg.result.behavior.formatters, "table" },
    json = { cfg.result.behavior.formatters.json, { "string", "function" } },
    html = { cfg.result.behavior.formatters.html, { "string", "function" } },
    -- RestConfigResultKeybinds
    result_keybinds = { cfg.result.keybinds, "table" },
    prev = { cfg.result.keybinds.prev, "string" },
    next = { cfg.result.keybinds.next, "string" },
    -- RestConfigHighlight
    highlight_enable = { cfg.highlight.enable, "boolean" },
    timeout = { cfg.highlight.timeout, "number" },
  })

  if not ok then
    return false, err
  end
  return true
end

---Recursively check a table for unrecognized keys,
---using a default table as a reference
---@param tbl table
---@param default_tbl table
---@return string[]
function check.get_unrecognized_keys(tbl, default_tbl)
  local unrecognized_keys = {}
  for k, _ in pairs(tbl) do
    unrecognized_keys[k] = true
  end
  for k, _ in pairs(default_tbl) do
    unrecognized_keys[k] = false
  end

  local ret = {}
  for k, _ in pairs(unrecognized_keys) do
    if unrecognized_keys[k] then
      ret[k] = k
    end
    if type(default_tbl[k]) == "table" and tbl[k] then
      for _, subk in pairs(check.get_unrecognized_keys(tbl[k], default_tbl[k])) do
        local key = k .. "." .. subk
        -- Keybinds configuration table requires a special treatment as it does not have a "static" syntax
        if k ~= "keybinds" or k == "keybinds" and type(subk) ~= "number" then
          ret[key] = key
        end
      end
    end
  end

  return vim.tbl_keys(ret)
end

return check
