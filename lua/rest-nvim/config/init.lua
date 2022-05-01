local M = {}

local config = {
  result_split_horizontal = false,
  result_split_in_place = false,
  skip_ssl_verification = false,
  highlight = {
    enabled = true,
    timeout = 150,
  },
  result = {
    show_url = true,
    show_http_info = true,
    show_headers = true,
  },
  jump_to_request = false,
  env_file = ".env",
  custom_dynamic_variables = {},
  yank_dry_run = true,
}

--- Get a configuration value
--- @param opt string
--- @return any
M.get = function(opt)
  -- If an option was passed then
  -- return the requested option.
  -- Otherwise, return the entire
  -- configurations.
  if opt then
    return config[opt]
  end

  return config
end

--- Set user-defined configurations
--- @param user_configs table
--- @return table
M.set = function(user_configs)
  vim.validate({ user_configs = { user_configs, "table" } })

  config = vim.tbl_deep_extend("force", config, user_configs)
  return config
end

return M
