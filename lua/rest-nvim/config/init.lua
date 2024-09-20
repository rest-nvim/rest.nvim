---@mod rest-nvim.config rest.nvim configuration
---
---@brief [[
---
--- rest.nvim configuration options
---
--- You can set rest.nvim configuration options via `vim.g.rest_nvim`.
---
--->lua
--- ---@type rest.Opts
--- vim.g.rest_nvim
---<
---
---@brief ]]

---@type rest.Config
local config

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
--- Set `User-Agent` header when it is empty. Set as empty string to disable.
--- (Default: `rest.nvim {version}`)
---@field user_agent? string
--- Set `Content-Type` header when it is empty but request body is provided
---@field set_content_type? boolean

---@class rest.Opts.Response
--- Default response hooks (aka. request handlers) configuration
---@field hooks? rest.Opts.Response.Hooks

---@class rest.Opts.Response.Hooks
--- Decode url segments on response UI too improve readability (Default: `true`)
---@field decode_url? boolean
--- Format the response body with |'formatexpr'| or |'formatprg'| (Default: `true`)
--- NOTE: |vim.lsp.formatexpr()| won't work (see
--- <https://github.com/rest-nvim/rest.nvim/issues/414#issuecomment-2308910953>)
---@field format? boolean

---@class rest.Opts.Clients
---@field curl? rest.Opts.Clients.Curl

---@class rest.Opts.Clients.Curl
--- Statistics to parse from curl request output
---@field statistics? RestStatisticsStyle[]
--- Curl-specific options
---@field opts? rest.Opts.Clients.Curl.Opts

---@class rest.Opts.Clients.Curl.Opts
--- Add `--compressed` argument when `Accept-Encoding` header includes `gzip`
--- (Default: `false`)
---@field set_compressed? boolean

---@class RestStatisticsStyle
--- Identifier used used in curl's `--write-out` option
--- See `man curl` for more info
---@field id string
--- Title used on Statistics pane
---@field title? string
--- Winbar title. Set to `false` or `nil` to not show for winbar, set to empty string
--- to hide title If true, rest.nvim will use lowered `title` field
---@field winbar? string|boolean

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

local default_config = require("rest-nvim.config.default")

local check = require("rest-nvim.config.check")
local opts = vim.g.rest_nvim or {}
config = vim.tbl_deep_extend("force", default_config, opts)
---@cast config rest.Config
local ok, err = check.validate(config)

if not ok then
    vim.notify(err, vim.log.levels.ERROR, { title = "rest.nvim" })
end

return config
