---@mod rest-nvim.request_ rest.nvim request APIs

local M = {}

local parser = require("rest-nvim.parser")
local utils   = require("rest-nvim.utils")

---@class Request_
---@field context Context
---@field name? string The request identifier
---@field method string The request method
---@field url string The request URL
---@field http_version? string The request HTTP protocol
---@field headers table<string,string>
---@field body? ReqBody
---@field handlers fun()[]

---@type Request_|nil
_G._rest_nvim_last_request_ = nil

---@param req Request_
---@return boolean ok
local function run_request(req)
  local logger = assert(_G._rest_nvim.logger)
  local client = require("rest-nvim.client.curl")
  _G._rest_nvim_last_request_ = req

  local res = client.request_(req)
  if not res then
    logger:error("request failed")
    return false
  end

  -- run request handler scripts
  -- TODO: run them with response info
  vim.iter(req.handlers):each(function (f) f() end)

  -- update result UI
  local result = require("rest-nvim.result")
  local result_buf = result.get_or_create_buf()
  result.write_res(result_buf, res)
  return true
end

---run request in current cursor position
---@return boolean ok
function M.run()
  local logger = assert(_G._rest_nvim.logger)
  local req_node = parser.get_cursor_request_node()
  if not req_node then
    logger:error("failed to find request at cursor position")
    return false
  end
  local ctx = parser.create_context(0)
  if vim.b._rest_nvim_env_file then
    ctx:load_file(vim.b._rest_nvim_env_file)
  end
  local req = parser.parse(req_node, 0, ctx)
  if not req then
    logger:error("failed to parse request")
    return false
  end
  local highlight = _G._rest_nvim.highlight
  if highlight.enable then
    utils.ts_highlight_node(0, req_node, require("rest-nvim.api").namespace)
  end
  return run_request(req)
end

---run last request
---@return boolean ok
function M.run_last()
  local logger = assert(_G._rest_nvim.logger)
  local req = _G._rest_nvim_last_request_
  if not req then
    logger:warn("no last request")
    return false
  end
  return run_request(req)
end

---run all requests in current file with same context
---@return boolean ok
function M.run_all()
  local logger = assert(_G._rest_nvim.logger)
  logger:error("not implemented")
  local reqs = parser.get_all_request_node()
  local ctx = parser.create_context(0)
  for _, req_node in ipairs(reqs) do
    local req = parser.parse(req_node, 0, ctx)
    if not req then
      logger:error("failed to run request")
      return false
    end
    local ok = run_request(req)
    if not ok then
      return false
    end
  end
  return true
end

return M
