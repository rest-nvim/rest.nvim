---@mod rest-nvim.context_ rest.nvim context (mainly contains variables)

local dotenv = require("rest-nvim.dotenv")
local config = require("rest-nvim.config")
local M = {}

---@class rest.Context
---@field vars table<string,string>
local Context = {}
Context.__index = Context

local random = math.random
math.randomseed(os.time())

---Generate a random uuid
---@return string
local function uuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  local s = string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)
  return s
end

---@type table<string,fun():string>
local rest_variables = {
  ["$uuid"] = uuid,
  ["$date"] = function()
    return os.date("%Y-%m-%d") --[[@as string]]
  end,
  ["$timestamp"] = function()
    return string(os.time()) or ""
  end,
  ["$randomInt"] = function()
    return string(math.random(0, 1000))
  end,
}

---@return rest.Context
function Context:new()
  ---@type rest.Context
  local obj = {
    __index = self,
    vars = {},
    ---@diagnostic disable-next-line: missing-fields
    response = {}, -- create response table here to pass the reference first
  }
  setmetatable(obj, self)
  return obj
end

---@param filepath string
function Context:load_file(filepath)
  dotenv.load_file(filepath, function (key, value)
    self:set(key, value)
  end)
end

---@param key string
---@param value string
function Context:set(key, value)
  self.vars[key] = value
end

---@param key string
---@return nil|fun():string
local function get_dynamic_vars(key)
  local user_variables = config.custom_dynamic_variables
  return user_variables[key] or rest_variables[key]
end

---resolves variable
---1. variables from pre-request scripts (local to each requests)
---2. in-place variables (local to each .http files)
---3. selected dotenv file (local to each .http files)
---returns empty string if variable is not set
---@param key string
---@return string value
function Context:resolve(key)
  -- find from dynamic variables
  local var = get_dynamic_vars(key)
  -- find from local variable table or vim.env
  return var and var() or self.vars[key] or vim.env[key] or ""
end

M.Context = Context

return M
