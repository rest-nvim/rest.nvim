local logger = require("rest-nvim.logger")
local utils = require("rest-nvim.utils")

local M = {}

---Get the environment variables file filetype
---@param path string The environment file path
---@return string|nil
local function get_filetype(path)
  local ext = vim.fn.fnamemodify(path, ":e")
  return ext == "" and nil or ext
end

---@param value any
---@return string
local function value_tostring(value)
  vim.validate({
    value = {
      value,
      function (v)
        return v == vim.NIL or vim.tbl_contains({ "nil", "number", "string", "boolean" }, type(value))
      end,
      "vim.NIL|nil|bumber|string|boolean"
    }
  })
  if value == vim.NIL or value == nil then
    return ""
  end
  return tostring(value)
end

---parse dotenv file
---with setter, it pass the values to setter function
---when setter isn't provided, returns variables table
---@param path string
---@param setter? fun(key:string,value:string)
---@return boolean ok
---@return table<string,string>|nil
function M.parse(path, setter)
  local vars
  if not setter then
    vars = {}
    setter = function (key, value)
      vars[key] = value
    end
  end
  if not utils.file_exists(path) then
    logger.error("Current environment file '" .. path .. "' was not found")
    return false
  end
  local env_ext = get_filetype(path)
  local file_contents = utils.read_file(path)
  if env_ext == "json" then
    local ok, json_tbl = pcall(vim.json.decode, file_contents)
    if not ok or type(json_tbl) ~= "table" or vim.islist(json_tbl) then
      logger.error("failed parsing json data")
      return false
    end
    for key, value in pairs(json_tbl) do
      if type(key) == "string" and type(value) ~= "table" then
        setter(key, value_tostring(value))
      end
    end
  else
    local vars_tbl = vim.split(file_contents, "\n")
    table.remove(vars_tbl, #vars_tbl)
    for _, var in ipairs(vars_tbl) do
      local variable = vim.split(var, "=")
      local variable_name = variable[1]
      local variable_value
      -- In case some weirdo adds a `=` character to his ENV value
      if #variable > 2 then
        table.remove(variable, 1)
        variable_value = table.concat(variable, "=")
      else
        variable_value = variable[2]
      end
      setter(variable_name, value_tostring(variable_value))
    end
  end
  return true, vars
end

return M
