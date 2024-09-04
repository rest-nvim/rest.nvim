---@mod rest-nvim.request rest.nvim request APIs

local M = {}

local parser = require("rest-nvim.parser")
local utils = require("rest-nvim.utils")
local logger = require("rest-nvim.logger")
local config = require("rest-nvim.config")
local ui = require("rest-nvim.ui.result")
local nio = require("nio")
local jar = require("rest-nvim.cookie_jar")
local clients = require("rest-nvim.client")
local Context = require("rest-nvim.context").Context

---@class rest.Request.Body
---@field __TYPE "json"|"xml"|"raw"|"graphql"|"multipart_form_data"|"external"
---@field data any

---@class rest.Request
---The request identifier (`nil` on anonymous requests. e.g. parsed from raw string)
---@field name? string
---@field method string The request method
---@field url string The request URL
---@field http_version? string The request HTTP protocol
---@field headers table<string,string[]>
---@field cookies rest.Cookie[]
---@field body? rest.Request.Body
---@field handlers fun()[]

---@class rest.Response
---@field status rest.Response.status Status information from response
---@field body string? Raw response body
---@field headers table<string,string[]> Response headers

---@class rest.Response.status
---@field code number
---@field version string
---@field text string

---@type rest.Request|nil
local rest_nvim_last_request = nil

---@param req rest.Request
local function run_request(req)
    logger.debug("running request:" .. req.name)
    local client = clients.get_available_clients(req)[1]
    if not client then
        logger.error("can't find registered client available for request:\n" .. vim.inspect(req))
        vim.notify("Can't find registered client available for request", vim.log.levels.ERROR, { title = "rest.nvim" })
        return
    end
    rest_nvim_last_request = req

    _G.rest_request = req
    vim.api.nvim_exec_autocmds("User", {
        pattern = { "RestRequest", "RestRequestPre" },
    })
    _G.rest_request = nil

    ui.update({ request = req })

    -- NOTE: wrap with schedule to do vim stuffs outside of lua callback loop (`on_exit`
    -- callback from `vim.system()` call)
    nio.run(function()
        local ok, res = pcall(client.request(req).wait)
        if not ok then
            logger.error("request failed")
            vim.notify("request failed. See `:Rest logs` for more info", vim.log.levels.ERROR, { title = "rest.nvim" })
            return
        end
        ---@cast res rest.Result
        logger.info("request success")

        local last_response = res.requests[#res.requests].response

        -- run request handler scripts
        vim.iter(req.handlers):each(function(f)
            f(res)
        end)
        logger.info("handler done")

        _G.rest_request = req
        _G.rest_response = last_response
        vim.api.nvim_exec_autocmds("User", {
            pattern = { "RestResponse", "RestResponsePre" },
        })
        _G.rest_request = nil
        _G.rest_response = nil

        -- update cookie jar
        jar.update_jar(req.url, last_response)

        -- update result UI
        ui.update({ response = last_response, statistics = res.statistics })
    end)
    -- FIXME(boltless): return future to pass the command state
end

---Run request in current file.
---When `name` is not provided, run request on cursor position
---@param name string|nil name of the request
function M.run(name)
    local req_node = parser.get_request_node(name)
    if not req_node then
        return
    end
    local ctx = Context:new()
    if config.env.enable and vim.b._rest_nvim_env_file then
        ctx:load_file(vim.b._rest_nvim_env_file)
    end
    local req = parser.parse(req_node, 0, ctx)
    if not req then
        logger.error("failed to parse request")
        vim.notify("failed to parse request", vim.log.levels.ERROR, { title = "rest.nvim" })
        return
    end
    local highlight = config.highlight
    if highlight.enable then
        utils.ts_highlight_node(0, req_node, require("rest-nvim.api").namespace, highlight.timeout)
    end
    run_request(req)
end

---run last request
function M.run_last()
    local req = rest_nvim_last_request
    if not req then
        vim.notify("No last request found", vim.log.levels.WARN, { title = "rest.nvim" })
        return false
    end
    run_request(req)
end

function M.last_request()
    return rest_nvim_last_request
end

-- ---run all requests in current file with same context
-- function M.run_all()
--     local reqs = parser.get_all_request_nodes(0)
--     local ctx = Context:new()
--     for _, req_node in ipairs(reqs) do
--         local req = parser.parse(req_node, 0, ctx)
--         if not req then
--             vim.notify(
--                 "Parsing request failed. See `:Rest logs` for more info",
--                 vim.log.levels.ERROR,
--                 { title = "rest.nvim" }
--             )
--             return false
--         end
--         -- FIXME: wait for previous request ends
--         local ok = run_request(req)
--         if not ok then
--             vim.notify(
--                 "Running request failed. See `:Rest logs` for more info",
--                 vim.log.levels.ERROR,
--                 { title = "rest.nvim" }
--             )
--             return
--         end
--     end
-- end

return M
