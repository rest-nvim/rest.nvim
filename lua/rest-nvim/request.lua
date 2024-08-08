---@mod rest-nvim.request_ rest.nvim request APIs

local M = {}

local parser = require("rest-nvim.parser")
local utils  = require("rest-nvim.utils")
local logger = require("rest-nvim.logger")
local config = require("rest-nvim.config")
local ui     = require("rest-nvim.ui.result")
local nio    = require("nio")
local response = require("rest-nvim.response")

---@class Request
---@field context Context
---@field name? string The request identifier
---@field method string The request method
---@field url string The request URL
---@field http_version? string The request HTTP protocol
---@field headers table<string,string>
---@field body? ReqBody
---@field handlers fun()[]

---@type Request|nil
local rest_nvim_last_request = nil

---@param req Request
---@return boolean ok
local function run_request(req)
  logger.debug("run_request")
  local client = require("rest-nvim.client.curl.cli")
  rest_nvim_last_request = req

  -- remove previous result
  response.current = nil
  -- clear the ui
  ui.update()

  -- open result UI
  ui.open_ui()

  -- TODO: set UI with request informations (e.g. method & get)

  nio.run(function ()
    local ok, res = pcall(client.request(req).wait)
    if not ok then
      logger.error("request failed")
      -- TODO: should return here
      return
    end
    ---@cast res rest.Response
    logger.info("request success")
    response.current = res

    -- run request handler scripts
    vim.iter(req.handlers):each(function (f) f() end)
    logger.info("handler done")

    -- update result UI
    -- NOTE: wrap with schedule to set vim variable outside of lua callback loop
    vim.schedule(ui.update)
  end)
  -- FIXME: use future instead of returning true here
  return true
end

---run request in current cursor position
---@return boolean ok
function M.run()
  logger.info("starting request")
  local req_node = parser.get_cursor_request_node()
  if not req_node then
    logger.error("failed to find request at cursor position")
    return false
  end
  local ctx = parser.create_context(0)
  if vim.b._rest_nvim_env_file then
    ctx:load_file(vim.b._rest_nvim_env_file)
  end
  local req = parser.parse(req_node, 0, ctx)
  if not req then
    logger.error("failed to parse request")
    return false
  end
  local highlight = config.highlight
  if highlight.enable then
    utils.ts_highlight_node(0, req_node, require("rest-nvim.api").namespace)
  end
  return run_request(req)
end

---run last request
---@return boolean ok
function M.run_last()
  local req = rest_nvim_last_request
  if not req then
    vim.notify("No last request found", vim.log.levels.WARN)
    return false
  end
  return run_request(req)
end

---run all requests in current file with same context
---@return boolean ok
function M.run_all()
  local reqs = parser.get_all_request_node()
  local ctx = parser.create_context(0)
  for _, req_node in ipairs(reqs) do
    local req = parser.parse(req_node, 0, ctx)
    if not req then
      vim.notify("Parsing request failed. See `:Rest logs` for more info", vim.log.levels.ERROR)
      return false
    end
    local ok = run_request(req)
    if not ok then
      vim.notify("Running request failed. See `:Rest logs` for more info", vim.log.levels.ERROR)
      return false
    end
  end
  return true
end

return M
