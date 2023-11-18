local M = {}

local config = {
  result_split_horizontal = false,
  result_split_in_place = false,
  stay_in_current_window_after_split = false,
  skip_ssl_verification = false,
  encode_url = true,
  highlight = {
    enabled = true,
    timeout = 150,
  },
  result = {
    show_curl_command = true,
    show_url = true,
    show_http_info = true,
    show_headers = true,
    show_statistics = false,
    formatters = {
      json = "jq",
      html = function(body)
        if vim.fn.executable("tidy") == 0 then
          return body
        end
        -- stylua: ignore
        return vim.fn.system({
          "tidy", "-i", "-q",
          "--tidy-mark",      "no",
          "--show-body-only", "auto",
          "--show-errors",    "0",
          "--show-warnings",  "0",
          "-",
        }, body):gsub("\n$", "")
      end,
    },
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
