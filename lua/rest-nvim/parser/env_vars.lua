---@mod rest-nvim.parser.env_vars rest.nvim parsing module environment variables
---
---@brief [[
---
--- rest.nvim environment variables
---
---@brief ]]

local env_vars = {}

local utils = require("rest-nvim.utils")

-- NOTE: vim.loop has been renamed to vim.uv in Neovim >= 0.10 and will be removed later
local uv = vim.uv or vim.loop

---Get the environment variables file filetype
---@param env_file string The environment file path
---@return string|nil
local function get_env_filetype(env_file)
  local ext = vim.fn.fnamemodify(env_file, ":e")
  return ext == "" and nil or ext
end

---Read the environment variables file from the rest.nvim configuration
---and store all the environment variables in the `vim.env` metatable
---@see vim.env
function env_vars.read_file()
  local path = _G._rest_nvim.env_file
  local logger = _G._rest_nvim.logger

  if utils.file_exists(path) then
    local env_ext = get_env_filetype(path)
    local file_contents = utils.read_file(path)

    local variables = {}
    if env_ext == "json" then
      variables = vim.json.decode(file_contents)
    else
      local vars_tbl = vim.split(file_contents, "\n")
      table.remove(vars_tbl, #vars_tbl)
      for _, var in ipairs(vars_tbl) do
        local variable = vim.split(var, "=")
        local variable_name = variable[1]
        -- In case some weirdo adds a `=` character to his ENV value
        if #variable > 2 then
          table.remove(variable, 1)
          variable_value = table.concat(variable, "=")
        else
          variable_value = variable[2]
        end
        variables[variable_name] = variable_value
      end
    end

    for k, v in pairs(variables) do
      vim.env[k] = v
    end
  else
    ---@diagnostic disable-next-line need-check-nil
    logger:error("Current environment file '" .. path .. "' was not found in the current working directory")
  end
end

return env_vars
