---@mod rest-nvim.sscript rest.nvim tree-sitter parsing module

local logger = require("rest-nvim.logger")

local M = {}

-- TODO: fill script environment

---@class RestEnvRequestVariables
---@field set fun(key:string,value:string)
---@field get fun(key:string):string

---@param ctx Context
---@retrun RestPreScriptEnv
function M.create_prescript_env(ctx)
  ---@class RestPreScriptEnv
  local env = {
    ---@class RestPreScriptEnvRequest
    request = {
      ---@type RestEnvRequestVariables
      variables = {
        ---sets request-local variable
        set = function (key, value)
          ctx:set(key, value)
        end,
        ---retrieves variable in current request scope
        get = function (key)
          return ctx:resolve(key)
        end,
      }
    },
    vim = vim
  }
  return env
end

---@param ctx Context
---@return RestHandlerEnv
function M.create_handler_env(ctx)
  ---@class RestHandlerEnv
  local env = {
    ---@class RestHandlerEnvClient
    client = {
      test = function () end,
      assert = function () end,
      ---@type RestEnvRequestVariables
      global = {
        ---set global variable (this overwrites `vim.env`)
        set = function (key, value)
          vim.env[key] = value
        end,
        ---get global variable (return empty string if variable doesn't exist)
        get = function (key)
          return vim.env[key] or ""
        end,
      },
    },
    ---@class RestHandlerEnvRequest
    request = {
      body = {},
      environment = {},
      headers = {},
      method = "GET",
      url = "",
      ---@type RestEnvRequestVariables
      variables = {
        ---sets request-local variable
        set = function (key, value)
          ctx:set(key, value)
        end,
        ---retrieves variable in current request scope
        get = function (key)
          return ctx:resolve(key)
        end,
      }
    },
    ---@class RestHandlerEnvResponse
    response = ctx.response,
      -- body
      -- headers
      -- status
      -- content_type
    vim = vim
  }
  return env
end

---@param script string
---@param env table
---@return function
function M.load(script, env)
  local f, error_msg = load(script, "script_variable", "bt", env)
  if error_msg then
    logger.error(error_msg)
  end
  return assert(f)
end

---@param script string
---@param ctx Context
---@return function
function M.load_prescript(script, ctx)
  return M.load(script, M.create_prescript_env(ctx))
end

---@param script string
---@param ctx Context
---@return function
function M.load_handler(script, ctx)
  return M.load(script, M.create_handler_env(ctx))
end

return M
