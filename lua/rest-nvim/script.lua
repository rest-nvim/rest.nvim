---@mod rest-nvim.sscript rest.nvim tree-sitter parsing module

local logger = require("rest-nvim.logger")

local M = {}

---@class rest.Env.Request.Variables
---@field set fun(key:string,value:string)
---@field get fun(key:string):string

---@param ctx rest.Context
---@return rest.PreScriptEnv
function M.create_prescript_env(ctx)
  ---@class rest.PreScriptEnv
  local env = {
    ---@class rest.PreScriptEnv.Request
    request = {
      ---@type rest.Env.Request.Variables
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

---@param ctx rest.Context
---@param res rest.Response
---@return rest.HandlerEnv
function M.create_handler_env(ctx, res)
  ---@class rest.HandlerEnv
  local env = {
    ---@class rest.HandlerEnv.Client
    client = {
      ---@type rest.Env.Request.Variables
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
    ---@class rest.HandlerEnv.Request
    request = {
      ---@type rest.Env.Request.Variables
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
    -- TODO: create wrapper class for response
    response = res,
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
---@param ctx rest.Context
---@return function
function M.load_prescript(script, ctx)
  return M.load(script, M.create_prescript_env(ctx))
end

---@param script string
---@param ctx rest.Context
---@return function
function M.load_handler(script, ctx)
  return function (res)
    M.load(script, M.create_handler_env(ctx, res))()
  end
end

return M
