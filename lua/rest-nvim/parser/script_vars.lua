---@mod rest-nvim.parser.script_vars rest.nvim parsing module script variables
---
---@brief [[
---
--- rest.nvim script variables
---
---@brief ]]

local script_vars = {}

local env_vars = require("rest-nvim.parser.env_vars")

---Load a script_variable content and evaluate it
---@param script_str string The script variable content
---@param res table Request response body
function script_vars.load(script_str, res)
  local context = {
    result = res,
    print = vim.print,
    json_decode = vim.json.decode,
    set_env = env_vars.set_var,
  }
  local env = { context = context }
  setmetatable(env, { __index = _G })

  local f = load(script_str, "script_variable", "bt", env)
  if f then
    f()
  end
end

return script_vars
