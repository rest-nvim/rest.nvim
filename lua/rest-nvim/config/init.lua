---@mod rest-nvim.config rest.nvim configuration
---
---@brief [[
---
--- rest.nvim configuration options
---
---@brief ]]

local config = {}

---@class RestConfigDebug
---@field unrecognized_configs string[] Unrecognized configuration options

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
---@field formatters RestConfigResultFormatters Formatters for the request results body

---@class RestConfigResultInfo
---@field url boolean Display the request URL
---@field headers boolean Display the request headers
---@field http_info boolean Display the request HTTP information
---@field curl_command boolean Display the cURL command that was used for the request

---@class RestConfigResultStats
---@field enable boolean Whether enable statistics or not
---@field stats string[]|{ [1]: string, title?: string, type: string }[] Statistics to be shown, takes cURL's `--write-out` options

---@class RestConfigResultFormatters
---@field json string|fun(body: string): string JSON formatter
---@field html string|fun(body: string): string HTML formatter

---@class RestConfigHighlight
---@field enable boolean Whether current request highlighting is enabled or not
---@field timeout number Duration time of the request highlighting in milliseconds

---@class RestConfig
---@field client string The HTTP client to be used when running requests, default is `curl`
---@field env_file string Environment variables file to be used for the request variables in the document
---@field encode_url boolean Encode URL before making request
---@field yank_dry_run boolean Whether to copy the request preview (cURL command) to the clipboard
---@field skip_ssl_verification boolean Skip SSL verification, useful for unknown certificates
---@field custom_dynamic_variables { [string]: fun(): string }[] Table of custom dynamic variables
---@field result RestConfigResult Request results buffer behavior
---@field highlight RestConfigHighlight Request highlighting
---@field keybinds { [1]: string, [2]: string, [3]: string }[] Keybindings list
---@field debug_info? RestConfigDebug Configurations debug information, set automatically

---rest.nvim default configuration
---@type RestConfig
local default_config = {
  client = "curl",
  env_file = ".env",
  encode_url = true,
  yank_dry_run = true,
  skip_ssl_verification = false,
  custom_dynamic_variables = {},
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
        stats = {
          { "time_total", title = "Total time: ", type = "time" },
          { "size_download", title = "Request download size: ", type = "byte" },
        },
      },
      formatters = {
        json = "jq",
        html = function(body)
          if vim.fn.executable("tidy") == 0 then
            return body
          end
          -- stylua: ignore
          return vim.fn.system({
            "tidy",
            "-i",
            "-q",
            "--tidy-mark",      "no",
            "--show-body-only", "auto",
            "--show-errors",    "0",
            "--show-warnings",  "0",
            "-",
          }, body):gsub("\n$", "")
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
---@return RestConfig
function config.set(user_configs)
  local check = require("rest-nvim.config.check")

  local conf = vim.tbl_deep_extend("force", {
    debug_info = {
      unrecognized_configs = check.get_unrecognized_keys(user_configs, default_config),
    },
  }, default_config, user_configs)

  local ok, err = check.validate(conf)
  if not ok then
    vim.notify("Rest: " .. err, vim.log.levels.ERROR)
  end

  if #conf.debug_info.unrecognized_configs > 0 then
    vim.notify(
      "Rest: Unrecognized configs found in setup: " .. vim.inspect(config.debug_info.unrecognized_configs),
      vim.log.levels.WARN
    )
  end

  return conf
end

return config
