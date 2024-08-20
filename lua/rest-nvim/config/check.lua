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
---@param cfg rest.Config
---@return boolean is_valid
---@return string|nil error_message
function check.validate(cfg)
  local ok, err = validate({
    custom_dynamic_variables = { cfg.custom_dynamic_variables, "table" },
    request = { cfg.request, "table" },
    ["request.skip_ssl_verification"] = { cfg.request.skip_ssl_verification, "boolean" },
    ["request.hooks"] = { cfg.request.hooks, "table" },
    ["request.hooks.encode_url"] = { cfg.request.hooks.encode_url, "boolean" },
    ["request.hooks.user_agent"] = { cfg.request.hooks.user_agent, { "function", "string" } },
    ["request.hooks.set_content_type"] = { cfg.request.hooks.set_content_type, "boolean" },
    response = { cfg.response, "table" },
    ["response.hooks"] = { cfg.response.hooks, "table" },
    clients = { cfg.clients, "table" },
    ["clients.curl"] = { cfg.clients.curl, "table" },
    ["clients.curl.statistics"] = { cfg.clients.curl.statistics, "table" },
    cookies = { cfg.cookies, "table" },
    ["cookies.enable"] = { cfg.cookies.enable, "boolean" },
    ["cookies.path"] = { cfg.cookies.path, "string" },
    env = { cfg.env, "table" },
    ["env.enable"] = { cfg.env.enable, "boolean" },
    ["env.path"] = { cfg.env.pattern, "string" },
    ui = { cfg.ui, "table" },
    ["ui.winbar"] = { cfg.ui.winbar, "boolean" },
    ["ui.keybinds"] = { cfg.ui.keybinds, "table" },
    ["ui.keybinds.prev"] = { cfg.ui.keybinds.prev, "string" },
    ["ui.keybinds.next"] = { cfg.ui.keybinds.next, "string" },
    highlight = { cfg.highlight, "table" },
    ["highlight.enable"] = { cfg.highlight.enable, "boolean" },
    ["highlight.timeout"] = { cfg.highlight.timeout, "number" },
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
