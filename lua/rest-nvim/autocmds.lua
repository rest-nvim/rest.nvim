---@mod rest-nvim.events rest.nvim user events
---
---@brief [[
---
--- rest.nvim user events
---
---rest.nvim provides several |User| |events|.
---
---RestRequest or RestRequestPre                   *RestRequest* *RestRequestPre*
---    Just before executing a request. The request object (with |rest.Request|
---    type) will be temporarily assigned to the global variable `rest_request`.
---    Modifing this variable will affect the actual request. Example: >lua
---
---    vim.api.nvim_create_autocmd("User", {
---        pattern = "RestRequestPre",
---        callback = function()
---            local req = _G.rest_request
---            req.headers["user-agent"] = { "myneovim" }
---        end,
---    })
---<
---
---RestResponse or RestResponsePre               *RestResponse* *RestResponsePre*
---    After received the response and all response handlers are executed.
---    The request and response objects (|rest.Request| and |rest.Response|
---    types) will be termporarily assigned to the global variabels
---    `rest_request` and `rest_response`. Modifing this variable won't affect
---    response handlers but updating cookies and rendering result UI will be
---    affected. Example: >lua
---
---    vim.api.nvim_create_autocmd("User", {
---        pattern = "RestResponsePre",
---        callback = function()
---            local req = _G.rest_request
---            local res = _G.rest_response
---            req.url = url_decode(req.url)
---            res.body = trim_trailing_whitespace(res.body)
---        end,
---    })
---<
---
---@brief ]]

local autocmds = {}

---Set up Rest autocommands group
---@package
function autocmds.setup()
    vim.api.nvim_create_augroup("Rest", { clear = true })

    vim.api.nvim_create_autocmd("User", {
        pattern = "RestRequestPre",
        callback = function(_ev)
            local config = require("rest-nvim.config")
            local utils = require("rest-nvim.utils")
            local req = _G.rest_request
            local hooks = config.request.hooks
            if hooks.encode_url then
                req.url = utils.escape(req.url, true)
            end
            if hooks.user_agent ~= "" then
                local header_empty = not req.headers["user-agent"] or #req.headers["user-agent"] < 1
                if header_empty then
                    local user_agent = type(hooks.user_agent) == "function" and hooks.user_agent() or hooks.user_agent
                    ---@cast user_agent string
                    req.headers["user-agent"] = { user_agent }
                end
            end
            if hooks.set_content_type then
                local header_empty = not req.headers["content-type"] or #req.headers["content-type"] < 1
                if header_empty and req.body then
                    if req.body.__TYPE == "json" then
                        req.headers["content-type"] = { "application/json" }
                    elseif req.body.__TYPE == "xml" then
                        req.headers["content-type"] = { "application/xml" }
                        -- TODO: auto-set content-type header for external body
                    end
                end
            end
        end,
    })
    vim.api.nvim_create_autocmd("User", {
        pattern = "RestResponsePre",
        callback = function(_ev)
            local config = require("rest-nvim.config")
            local utils = require("rest-nvim.utils")
            local req = _G.rest_request
            local _res = _G.rest_response
            if config.response.hooks.decode_url then
                req.url = utils.url_decode(req.url)
            end
        end,
    })
end

---Register a new autocommand in the `Rest` augroup
---@see vim.api.nvim_create_augroup
---@see vim.api.nvim_create_autocmd
---
---@param events string[] Autocommand events, see `:h events`
---@param cb string|fun(args: table) Autocommand lua callback, runs a Vimscript command instead if it is a `string`
---@param description string Autocommand description
---@package
function autocmds.register_autocmd(events, cb, description)
    vim.validate({
        events = { events, "table" },
        cb = { cb, { "function", "string" } },
        description = { description, "string" },
    })

    local autocmd_opts = {
        group = vim.api.nvim_create_augroup("Rest", { clear = false }),
        desc = description,
    }

    if type(cb) == "function" then
        autocmd_opts = vim.tbl_deep_extend("force", autocmd_opts, {
            callback = cb,
        })
    elseif type(cb) == "string" then
        autocmd_opts = vim.tbl_deep_extend("force", autocmd_opts, {
            command = cb,
        })
    end

    vim.api.nvim_create_autocmd(events, autocmd_opts)
end

return autocmds
