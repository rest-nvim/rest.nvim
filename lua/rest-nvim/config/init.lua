---@mod rest-nvim.config rest.nvim configuration
---
---@brief [[
---
--- rest.nvim configuration options
---
---@brief ]]

---@type RestConfig
local config = {}

---@alias RestResultFormatters string|fun(body:string):string,table

---@class RestOptsHighlight
--- Whether current request highlighting is enabled or not (Default: `true`)
---@field enable? boolean
--- Duration time of the request highlighting in milliseconds (Default: `250`)
---@field timeout? number

---@class RestOptsResult
---@field window? RestOptsResultWindow
---@field behavior? RestOptsResultBehavior
---@field keybinds? RestOptsResultKeybinds

---@class RestOptsResultWindow
--- Open request results in a horizontal split (Default: `false`)
---@field horizontal? boolean
---@field enter? boolean

---@class RestOptsResultBehavior
---@field decode_url boolean
---@field statistics RestOptsStatistics
---@field formatters table<string,RestResultFormatters>

---@class RestOptsStatistics
---@field enable boolean
---@field stats table<string,RestOptsResultStatStyle>

---@class RestOptsResultKeybinds
--- Mapping for cycle to previous result pane (Default: `"H"`)
---@field prev? string
--- Mapping for cycle to next result pane (Default: `"L"`)
---@field next? string

---@class RestOptsResultStatStyle
--- Title used on result pane
---@field title? string
--- Winbar title. Set to `false` or `nil` to not show for winbar, set to empty string
--- to hide title If true, rest.nvim will use lowered `title` field
---@field winbar? string|boolean

---@class RestOpts
--- Environment variables file pattern for telescope.nvim
--- (Default: `".*env.*$"`)
---@field env_pattern? string
--- Encode URL before making request (Default: `true`)
---@field encode_url? boolean
--- Skip SSL verification, useful for unknown certificates (Default: `false`)
---@field skip_ssl_verification? boolean
--- Table of custom dynamic variables
---@field custom_dynamic_variables? table<string, fun():string>
--- Request highlighting config
---@field highlight? RestOptsHighlight
--- Result view config
---@field result? RestOptsResult

---@type RestOpts
vim.g.rest_nvim = vim.g.rest_nvim

---rest.nvim default configuration
---@class RestConfig
local default_config = {
  ---@type string Environment variables file pattern for telescope.nvim
  env_pattern = ".*env.*$",

  ---@type boolean Encode URL before making request
  encode_url = true,
  ---@type boolean Skip SSL verification, useful for unknown certificates
  skip_ssl_verification = false,
  ---@type table<string, fun():string> Table of custom dynamic variables
  custom_dynamic_variables = {},

  ---@class RestConfigResult
  result = {
    ---@class RestConfigResultWindow
    window = {
      -- TODO: use `:horizontal` instead. see `:h command-modifiers` and opts.smods
      ---@type boolean Open request results in a horizontal split
      horizontal = false,
      ---@type boolean Change the focus to the results window or stay in the current window (HTTP file)
      enter = false,
      ---@type boolean
      headers = true,
      ---@type boolean
      cookies = true,
    },
    ---@class RestConfigResultBehavior
    behavior = {
      ---@type boolean Whether to decode the request URL query parameters to improve readability
      decode_url = true,
      ---@class RestConfigResultStats
      statistics = {
        ---@type boolean Whether enable statistics or not
        enable = true,
        ---Statistics to be shown, takes cURL's easy getinfo constants name
        ---@see https://curl.se/libcurl/c/curl_easy_getinfo.html
        ---@type table<string,RestOptsResultStatStyle>
        stats = {
          total_time = { winbar = "take", title = "Time taken" },
          size_download_t = { winbar = "size", title = "Download size" },
        },
      },
      ---@type table<string,RestResultFormatters>
      formatters = {
        json = "jq",
        html = function(body)
          if vim.fn.executable("tidy") == 0 then
            return body, { found = false, name = "tidy" }
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

          return fmt_body, { found = true, name = "tidy" }
        end,
      },
    },
    ---@class RestConfigResultKeybinds
    keybinds = {
      ---@type string Mapping for cycle to previous result pane
      prev = "H",
      ---@type string Mapping for cycle to next result pane
      next = "L",
    },
  },
  ---@class RestConfigHighlight
  highlight = {
    ---@type boolean Whether current request highlighting is enabled or not
    enable = true,
    ---@type number Duration time of the request highlighting in milliseconds
    timeout = 750,
  },
  ---@see vim.log.levels
  ---@type integer log level
  _log_level = vim.log.levels.WARN,
  ---@class RestConfigDebugInfo
  _debug_info = {
    -- NOTE: default option is `nil` to prevent overwriting as empty array
    ---@type string[]
    unrecognized_configs = nil,
  },
}

local check = require("rest-nvim.config.check")
local opts = vim.g.rest_nvim or {}
config = vim.tbl_deep_extend("force", {
  _debug_info = {
    unrecognized_configs = check.get_unrecognized_keys(opts, default_config),
  },
}, default_config, opts)
---@cast config RestConfig
local ok, err = check.validate(config)

if not ok then
  vim.notify("Rest.nvim: " .. err, vim.log.levels.ERROR)
end

if #config._debug_info.unrecognized_configs > 0 then
  vim.notify(
    "Unrecognized configs found in setup: " .. vim.inspect(config._debug_info.unrecognized_configs),
    vim.log.levels.WARN
  )
end

return config
