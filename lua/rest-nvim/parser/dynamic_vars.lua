---@mod rest-nvim.parser.dynamic_vars rest.nvim parsing module dynamic variables
---
---@brief [[
---
--- rest.nvim dynamic variables
---
---@brief ]]

local dynamic_vars = {}

local random = math.random
math.randomseed(os.time())

---Generate a random uuid
---@return string
local function uuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and random(0, 0xf) or random(8, 0xb)
    return string.format("%x", v)
  end)
end

---Retrieve all dynamic variables from both rest.nvim and the ones declared by
---the user on his configuration
---@return { [string]: fun():string }[]
function dynamic_vars.retrieve_all()
  local user_variables = _G._rest_nvim.custom_dynamic_variables or {}
  local rest_variables = {
    ["$uuid"] = uuid,
    ["$date"] = function()
      return os.date("%Y-%m-%d")
    end,
    ["$timestamp"] = os.time,
    ["$randomInt"] = function()
      return math.random(0, 1000)
    end,
  }

  return vim.tbl_deep_extend("force", rest_variables, user_variables)
end

---Look for a dynamic variable and evaluate it
---@param name string The dynamic variable name
---@return string|nil
function dynamic_vars.read(name)
  local logger = _G._rest_nvim.logger

  local vars = dynamic_vars.retrieve_all()
  if not vim.tbl_contains(vim.tbl_keys(vars), name) then
    ---@diagnostic disable-next-line need-check-nil
    logger:error(
      "The dynamic variable '" .. name .. "' was not found. Maybe it's written wrong or doesn't exist?"
    )
    return nil
  end

  return vars[name]()
end

return dynamic_vars
