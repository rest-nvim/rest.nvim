---@mod rest-nvim.config rest.nvim configuration
---
---@brief [[
---
--- rest.nvim configuration options
---
---@brief ]]

local config = {}

local logger = require("rest-nvim.logger")

---@class RestConfigDebug
---@field unrecognized_configs string[] Unrecognized configuration options

---@class RestConfigLogs
---@field level string The logging level name, see `:h vim.log.levels`. Default is `"info"`
---@field save boolean Whether to save log messages into a `.log` file. Default is `true`

---@class RestConfigResult
---@field split RestConfigResultSplit Result split window behavior
---@field behavior RestConfigResultBehavior Result buffer behavior

---@class RestConfigResultSplit
---@field horizontal boolean Open request results in a horizontal split
---@field in_place boolean Keep the HTTP file buffer above|left when split horizontal|vertical
---@field stay_in_current_window_after_split boolean Stay in the current window (HTTP file) or change the focus to the results window

---@class RestConfigResultBehavior
---@field show_info RestConfigResultInfo Request results information
---@field statistics RestConfigResultStats Request results statistics
---@field formatters RestConfigResultFormatters Formatters for the request results body. If the formatter is a function it should return two values, the formatted body and a boolean whether the formatter has been found or not

---@class RestConfigResultInfo
---@field url boolean Display the request URL
---@field headers boolean Display the request headers
---@field http_info boolean Display the request HTTP information
---@field curl_command boolean Display the cURL command that was used for the request

---@class RestConfigResultStats
---@field enable boolean Whether enable statistics or not
---@field stats string[]|{ [1]: string, title: string }[] Statistics to be shown, takes cURL's easy getinfo constants name

---@class RestConfigResultFormatters
---@field json string|fun(body: string): string,boolean JSON formatter
---@field html string|fun(body: string): string,boolean HTML formatter

---@class RestConfigHighlight
---@field enable boolean Whether current request highlighting is enabled or not
---@field timeout number Duration time of the request highlighting in milliseconds

---@class RestConfig
---@field client string The HTTP client to be used when running requests, default is `"curl"`
---@field env_file string Environment variables file to be used for the request variables in the document
---@field env_pattern string Environment variables file pattern for telescope.nvim
---@field env_edit_command string Neovim command to edit an environment file, default is `"tabedit"`
---@field encode_url boolean Encode URL before making request
---@field skip_ssl_verification boolean Skip SSL verification, useful for unknown certificates
---@field custom_dynamic_variables { [string]: fun(): string }[] Table of custom dynamic variables
---@field logs RestConfigLogs Logging system configuration
---@field result RestConfigResult Request results buffer behavior
---@field highlight RestConfigHighlight Request highlighting
---@field keybinds { [1]: string, [2]: string, [3]: string }[] Keybindings list
---@field debug_info? RestConfigDebug Configurations debug information, set automatically
---@field logger? Logger Logging system, set automatically

---rest.nvim default configuration
---@type RestConfig
local default_config = {
  client = "curl",
  env_file = ".env",
  env_pattern = "\\.env$",
  env_edit_command = "tabedit",
  encode_url = true,
  skip_ssl_verification = false,
  custom_dynamic_variables = {},
  logs = {
    level = "info",
    save = true,
  },
  result = {
    split = {
      horizontal = false,
      in_place = false,
      stay_in_current_window_after_split = true,
    },
    behavior = {
      show_info = {
        url = true,
        headers = true,
        http_info = true,
        curl_command = true,
      },
      statistics = {
        enable = true,
        ---@see https://curl.se/libcurl/c/curl_easy_getinfo.html
        stats = {
          { "total_time", title = "Time taken:" },
          { "size_download_t", title = "Download size:" },
        },
      },
      formatters = {
        json = "jq",
        html = function(body)
          if vim.fn.executable("tidy") == 0 then
            return body, false
          end
          -- stylua: ignore
          local fmt_body = vim.fn.system({
            "tidy",
            "-i",
            "-q",
            "--tidy-mark",      "no",
            "--show-body-only", "auto",
            "--show-errors",    "0",
            "--show-warnings",  "0",
            "-",
          }, body):gsub("\n$", "")

          return fmt_body, true
        end,
      },
    },
  },
  highlight = {
    enable = true,
    timeout = 150,
  },
  ---Example:
  ---
  ---```lua
  ---keybinds = {
  ---  "<localleader>r", "<Plug>(RestRun)", "Run request under the cursor",
  ---}
  ---
  ---```
  ---@see vim.keymap.set
  keybinds = {},
}

---Set user-defined configurations for rest.nvim
---@param user_configs RestConfig User configurations
---@return RestConfig rest.nvim configuration table
function config.set(user_configs)
  local check = require("rest-nvim.config.check")

  local conf = vim.tbl_deep_extend("force", {
    debug_info = {
      unrecognized_configs = check.get_unrecognized_keys(user_configs, default_config),
    },
  }, default_config, user_configs)

  local ok, err = check.validate(conf)

  -- We do not want to validate `logger` value so we are setting it after the validation
  conf.logger = logger:new({
    level_name = conf.logs.level,
    save_logs = conf.logs.save,
  })

  if not ok then
    ---@cast err string
    conf.logger:error(err)
  end

  if #conf.debug_info.unrecognized_configs > 0 then
    conf.logger:warn("Unrecognized configs found in setup: " .. vim.inspect(conf.debug_info.unrecognized_configs))
  end

  return conf
end

return config
