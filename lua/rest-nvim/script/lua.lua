---@mod rest-nvim.script.lua rest.nvim lua script runner
---@diagnostic disable: duplicate-set-field

---@type rest.ScriptClient
local script = {}

local logger = require("rest-nvim.logger")

---@class rest.Env.Request.Variables
---Set variable
---@field set fun(key:string,value:string)
---Retrieve variable
---@field get fun(key:string):string

---@param ctx rest.Context
---@return rest.PreScriptEnv
local function create_prescript_env(ctx)
    ---Global Environment variables passed to pre-request scripts
    ---@class rest.PreScriptEnv
    local env = {
        ---@class rest.PreScriptEnv.Request
        request = {
            ---@type rest.Env.Request.Variables
            variables = {
                ---Set request-local variable
                set = function(key, value)
                    ctx:set_local(key, value)
                end,
                ---Retrieve variable in current request scope
                get = function(key)
                    return ctx:resolve(key)
                end,
            },
        },
    }
    return env
end

---@param ctx rest.Context
---@param res rest.Response
---@return rest.HandlerEnv
local function create_handler_env(ctx, res)
    ---Global Environment variables passed to response handler scripts
    ---@class rest.HandlerEnv
    local env = {
        ---@class rest.HandlerEnv.Client
        client = {
            ---@type rest.Env.Request.Variables
            global = {
                ---Set global variable (this overwrites `vim.env`)
                set = function(key, value)
                    vim.env[key] = value
                end,
                ---Retrieve global variable (return empty string if variable doesn't exist)
                get = function(key)
                    return vim.env[key] or ""
                end,
            },
        },
        ---@class rest.HandlerEnv.Request
        request = {
            ---@type rest.Env.Request.Variables
            variables = {
                ---Set request-local variable
                set = function(key, value)
                    ctx:set_local(key, value)
                end,
                ---Retrieve variable in current request scope
                get = function(key)
                    return ctx:resolve(key)
                end,
            },
        },
        -- TODO: create wrapper class for response
        ---Raw response object
        ---@type rest.Response
        response = res,
    }
    return env
end

---@package
---@param s string
---@param env table
---@return function
local function load_lua(s, env)
    env = setmetatable(env, { __index = _G })
    local f, error_msg = load(s, "script_variable", "bt", env)
    if error_msg then
        logger.error(error_msg)
    end
    return assert(f)
end

---@param s string
---@param ctx rest.Context
---@return function
function script.load_pre_req_hook(s, ctx)
    return load_lua(s, create_prescript_env(ctx))
end

---@param s string
---@param ctx rest.Context
---@return function
function script.load_post_req_hook(s, ctx)
    return function(res)
        return load_lua(s, create_handler_env(ctx, res))()
    end
end

return script
