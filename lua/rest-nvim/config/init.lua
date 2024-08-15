---@mod rest-nvim.config rest.nvim configuration
---
---@brief [[
---
--- rest.nvim configuration options
---
--- You can set rest.nvim configuration options via `vim.g.rest_nvim`.
---
--->
--- ---@type rest.Opts
--- vim.g.rest_nvim
---<
---
---@brief ]]

---@type rest.Config
local config

---@alias RestResultFormatter string|fun(body:string):string,table

---@class RestStatisticsStyle
--- Title used on Statistics pane
---@field title? string
--- Winbar title. Set to `false` or `nil` to not show for winbar, set to empty string
--- to hide title If true, rest.nvim will use lowered `title` field
---@field winbar? string|boolean

---@tag vim.g.rest_nvim
---@tag g:rest_nvim
---@class rest.Opts
--- Table of custom dynamic variables
---@field custom_dynamic_variables? table<string, fun():string>
---@field request? rest.Opts.Request
---@field response? rest.Opts.Response
---@field clients? rest.Opts.Clients
---@field cookies? rest.Opts.Cookies
---@field env? rest.Opts.Env
---@field ui? rest.Opts.UI
---@field highlight? rest.Opts.Highlight

---@class rest.Opts.Request
--- Skip SSL verification, useful for unknown certificates (Default: `false`)
---@field skip_ssl_verification? boolean
--- Default request hooks (aka. pre-request scripts) configuration
---@field hooks? rest.Opts.Request.Hooks

---@class rest.Opts.Request.Hooks
--- Encode URL before making request (Default: `true`)
---@field encode_url? boolean

---@class rest.Opts.Response
--- Default response hooks (aka. request handlers) configuration
---@field hooks? rest.Opts.Response.Hooks
--- Formatters used for response format hook
---@field formatters? table<string,RestResultFormatter>

---@class rest.Opts.Response.Hooks
--- Decode url segments on response UI too improve readability (Default: `true`)
---@field decode_url? boolean
--- Format the response body (Default: `true`)
---@field format? boolean

---@class rest.Opts.Clients
---@field curl? rest.Opts.Clients.Curl

---@class rest.Opts.Clients.Curl
--- Statistics to parse from curl request output
--- Key is a string value of format used in `--write-out` option
--- See `man curl` for more info
---@field statistics? table<string,RestStatisticsStyle>

---@class rest.Opts.Cookies
--- Enable the cookies support (Default: `true`)
---@field enable? boolean
--- File path to save cookies file
--- (Default: `"stdpath("data")/rest-nvim.cookies"`)
---@field path? string

---@class rest.Opts.Env
--- Enable the `.env` files support (Default: `true`)
---@field enable? boolean
--- Environment variables file pattern for telescope.nvim (Default: `"%.env.*"`)
---@field pattern? string

---@class rest.Opts.UI
--- Set winbar in result pane (Default: `true`)
---@field winbar? boolean
--- Default mappings for result pane
---@field keybinds? rest.Opts.UI.Keybinds

---@class rest.Opts.UI.Keybinds
--- Mapping for cycle to previous result pane (Default: `"H"`)
---@field prev? string
--- Mapping for cycle to next result pane (Default: `"L"`)
---@field next? string

---@class rest.Opts.Highlight
--- Enable highlight-on-request (Default: `true`)
---@field enable? boolean
--- Duration time of the request highlighting in milliseconds (Default: `750`)
---@field timeout? number

---@type rest.Opts
vim.g.rest_nvim = vim.g.rest_nvim

---rest.nvim default configuration
---@class rest.Config
local default_config = {
  ---@type table<string, fun():string> Table of custom dynamic variables
  custom_dynamic_variables = {},
  ---@class rest.Config.Request
  request = {
    ---@type boolean Skip SSL verification, useful for unknown certificates
    skip_ssl_verification = false,
    ---Default request hooks
    ---@class rest.Config.Request.Hooks
    hooks = {
      ---@type boolean Encode URL before making request
      encode_url = true,
    },
  },
  ---@class rest.Config.Response
  response = {
    ---@class rest.Config.Response.Hooks
    hooks = {
      ---@type boolean Decode the request URL segments on response UI to improve readability
      decode_url = true,
      ---@type boolean Format the response body
      format = true,
    },
    ---@type table<string,RestResultFormatter>
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
  ---@class rest.Config.Clients
  clients = {
    ---@class rest.Config.Clients.Curl
    curl = {
      ---Statistics to be shown, takes cURL's `--write-out` flag variables
      ---See `man curl` for `--write-out` flag
      ---@type table<string,RestStatisticsStyle>
      statistics = {
        time_total = { winbar = "take", title = "Time taken" },
        size_download = { winbar = "size", title = "Download size" },
      },
    },
  },
  ---@class rest.Config.Cookies
  cookies = {
    ---@type boolean Whether enable cookies support or not
    enable = true,
    ---@type string Cookies file path
    path = vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "rest-nvim.cookies")
  },
  ---@class rest.Config.Env
  env = {
    ---@type boolean
    enable = true,
    ---@type string
    pattern = ".*%.env.*"
  },
  ---@class rest.Config.UI
  ui = {
    ---@type boolean Whether to set winbar to result panes
    winbar = true,
    ---@class rest.Config.UI.Keybinds
    keybinds = {
      ---@type string Mapping for cycle to previous result pane
      prev = "H",
      ---@type string Mapping for cycle to next result pane
      next = "L",
    },
  },
  ---@class rest.Config.Highlight
  highlight = {
    ---@type boolean Whether current request highlighting is enabled or not
    enable = true,
    ---@type number Duration time of the request highlighting in milliseconds
    timeout = 750,
  },
  ---@see vim.log.levels
  ---@type integer log level
  _log_level = vim.log.levels.WARN,
  ---@class rest.Config.DebugInfo
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
---@cast config rest.Config
local ok, err = check.validate(config)

if not ok then
  vim.notify("[rest.nvim] " .. err, vim.log.levels.ERROR)
end

if #config._debug_info.unrecognized_configs > 0 then
  vim.notify(
    "[rest.nvim] Unrecognized configs found in setup: " .. vim.inspect(config._debug_info.unrecognized_configs),
    vim.log.levels.WARN
  )
end

return config
