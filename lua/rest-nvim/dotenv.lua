---@mode rest-nvim.dotenv_ dotenv management module

local M = {}

local dotenv_parser = require("rest-nvim.parser.dotenv")
local config = require("rest-nvim.config")

---load dotenv file
---This function will set environment variables in current editor session.
---@see vim.env
---@param path string file path of dotenv file
---@param setter? fun(key:string, value:string)
function M.load_file(path, setter)
  vim.validate({
    path = { path, "string" },
    settter = { setter, { "function", "nil" }},
  })
  if not setter then
    setter = function (key, value)
      vim.env[key] = value
    end
  end
  local ok = dotenv_parser.parse(path, setter)
  if not ok then
    vim.notify("failed to load file '" .. path .. "'", vim.log.levels.WARN)
  end
end

---register the dotenv file.
---this file will be sourced right before each requests (it won't be sourced
---multiple times when running all requests in current http file)
---@param path string file path of dotenv file
---@param bufnr number? buffer identifier, default to current buffer
function M.register_file(path, bufnr)
  -- TODO: validate file extension
  bufnr = bufnr or 0
  vim.b[bufnr]._rest_nvim_env_file = path
  vim.notify("Env file '" .. path .. "' has been registered")
end

---show registered dotenv file for current buffer
---@param bufnr number? buffer identifier, default to current buffer
function M.show_registered_file(bufnr)
  bufnr = bufnr or 0
  if not vim.b[bufnr]._rest_nvim_env_file then
    vim.notify("No env file is used in current buffer", vim.log.levels.WARN)
  else
    vim.notify("Current env file in use: " .. vim.b._rest_nvim_env_file, vim.log.levels.INFO)
  end
end

---Find a list of environment files starting from the current directory
---@return string[] files Environment variable files path
function M.find_env_files()
  -- We are currently looking for any ".*env*" file, e.g. ".env", ".env.json"
  --
  -- This algorithm can be improved later on to search from a parent directory if the desired environment file
  -- is somewhere else but in the current working directory.
  local files = vim.fs.find(function(name, _)
    return name:match(config.env_pattern)
  end, { limit = math.huge, type = "file", path = "./" })

  return files
end

---@param bufnr number? buffer identifier, default to current buffer
---@return string? path
function M.select_file(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.ui.select(M.find_env_files(), {
     prompt = 'Select env files',
  }, function (item, _idx)
    M.register_file(item, bufnr)
  end)
end

return M
