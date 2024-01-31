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
    client = { cfg.client, "string" },
    env_file = { cfg.env_file, "string" },
    env_pattern = { cfg.env_pattern, "string" },
    env_edit_command = { cfg.env_edit_command, "string" },
    encode_url = { cfg.encode_url, "boolean" },
    skip_ssl_verification = { cfg.skip_ssl_verification, "boolean" },
    custom_dynamic_variables = { cfg.custom_dynamic_variables, "table" },
    keybinds = { cfg.keybinds, "table" },
    -- RestConfigLogs
    level = { cfg.logs.level, "string" },
    save = { cfg.logs.save, "boolean" },
    -- RestConfigResult
    result = { cfg.result, "table" },
    -- RestConfigResultSplit
    split = { cfg.result.split, "table" },
    horizontal = { cfg.result.split.horizontal, "boolean" },
    in_place = { cfg.result.split.in_place, "boolean" },
    stay_in_current_window_after_split = { cfg.result.split.stay_in_current_window_after_split, "boolean" },
    -- RestConfigResultBehavior
    behavior = { cfg.result.behavior, "table" },
    -- RestConfigResultInfo
    show_info = { cfg.result.behavior.show_info, "table" },
    url = { cfg.result.behavior.show_info.url, "boolean" },
    headers = { cfg.result.behavior.show_info.headers, "boolean" },
    http_info = { cfg.result.behavior.show_info.http_info, "boolean" },
    curl_command = { cfg.result.behavior.show_info.curl_command, "boolean" },
    -- RestConfigResultStats
    statistics = { cfg.result.behavior.statistics, "table" },
    statistics_enable = { cfg.result.behavior.statistics.enable, "boolean" },
    stats = { cfg.result.behavior.statistics.stats, "table" },
    -- RestConfigResultFormatters
    formatters = { cfg.result.behavior.formatters, "table" },
    json = { cfg.result.behavior.formatters.json, { "string", "function" } },
    html = { cfg.result.behavior.formatters.html, { "string", "function" } },
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
        ret[key] = key
      end
    end
  end

  return vim.tbl_keys(ret)
end

return check
