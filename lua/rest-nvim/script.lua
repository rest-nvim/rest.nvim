---@mod rest-nvim.sscript rest.nvim tree-sitter parsing module

local logger = require("rest-nvim.logger")

local M = {}

-- TODO: fill script environment

---@param ctx Context
---@return ScriptEnv
function M.create_env(ctx)
  ---@class ScriptEnv
  local env = {
    ---@class ScriptEnvClient
    client = {
      test = function () end,
      assert = function () end,
      ---@class ScriptEnvClientGlobal
      global = {
        ---@param key string
        ---@param value string
        set = function (key, value)
          vim.env[key] = value
        end,
        ---@param key string
        ---@return string value
        get = function (key)
          return ctx:resolve(key)
        end,
      },
    },
    ---@class ScriptEnvRequest
    request = {
      body = {},
      environment = {},
      headers = {},
      method = "GET",
      url = "",
      ---@class ScriptEnvRequestVariables
      variables = {
        ---sets request-local variable
        ---@param key string
        ---@param value string
        set = function (key, value)
          ctx:set(key, value)
        end,
      }
    },
    ---@class ScriptEnvResponse
    response = nil,
      -- body
      -- headers
      -- status
      -- content_type
  }
  return env
end

---load script for current context
---@param script string
---@return function
function M.load(script, context)
  local env = M.create_env(context)
  local f, error_msg = load(script, "script_variable", "bt", env)
  if error_msg then
    logger.error(error_msg)
  end
  return assert(f)
end

return M
