local config = require("rest-nvim.config")
local utils = require("rest-nvim.utils")
local M = {
  session_variables = {},
}

M.set_env = function(key, value, opts)
  if opts == nil then
    opts = { persist = false }
  end

  if opts.persist == true then
    local variables = M.get_env_variables()
    variables[key] = value
    M.write_env_file(variables)
  else
    M.session_variables[key] = value
  end
end

M.set_buffer_variable = function(key, value)
  local buf_vars = M.get_buffer_variables()
  buf_vars[key] = value
  vim.api.nvim_buf_set_var(0, "rest-nvim", buf_vars)
end

M.get_buffer_variables = function()
  local status_ok, buf_vars = pcall(function()
    return vim.api.nvim_buf_get_var(0, "rest-nvim")
  end)
  if status_ok then
    return buf_vars
  end
  return {}
end

M.write_env_file = function(variables)
  local env_file = "/" .. (config.get("env_file") or ".env")

  -- Directories to search for env files
  local env_file_paths = {
    -- current working directory
    vim.fn.getcwd() .. env_file,
    -- directory of the currently opened file
    vim.fn.expand("%:p:h") .. env_file,
  }

  -- If there's an env file in the current working dir
  for _, env_file_path in ipairs(env_file_paths) do
    if utils.file_exists(env_file_path) then
      local file = io.open(env_file_path, "w+")
      if file ~= nil then
        if string.match(env_file_path, "(.-)%.json$") then
          file:write(vim.fn.json_encode(variables))
        else
          for key, value in pairs(variables) do
            file:write(key .. "=" .. value .. "\n")
          end
        end
        file:close()
      end
    end
  end
end

M.read_document_variables = function()
  local variables = {}
  local bufnr = vim.api.nvim_get_current_buf()
  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    return variables
  end

  local first_tree = parser:trees()[1]
  if not first_tree then
    return variables
  end

  local root = first_tree:root()
  if not root then
    return variables
  end

  for node in root:iter_children() do
    local type = node:type()
    if type == "header" then
      local name = node:named_child(0)
      local value = node:named_child(1)
      variables[utils.get_node_value(name, bufnr)] = utils.get_node_value(value, bufnr)
    elseif type ~= "comment" then
      break
    end
  end
  return variables
end

M.read_variables = function()
  local first = M.get_variables()
  local second = M.read_dynamic_variables()
  local third = M.read_document_variables()
  local fourth = M.get_buffer_variables()

  return vim.tbl_extend("force", first, second, third, fourth)
end

-- reads the variables contained in the current file
M.get_file_variables = function()
  local variables = {}

  -- If there is a line at the beginning with @ first
  if vim.fn.search("^@", "cn") > 0 then
    -- Read all lines of the file
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

    -- For each line
    for _, line in pairs(lines) do
      -- Get the name and value form lines that starts with @
      local name, val = line:match("^@([%w!@#$%^&*-_+?~]+)%s*=%s*([^=]+)")
      if name then
        -- Add to variables
        variables[name] = val
      end
    end
  end
  return variables
end

-- Gets the variables from the currently selected env_file
M.get_env_variables = function()
  local variables = {}
  local env_file = "/" .. (config.get("env_file") or ".env")

  -- Directories to search for env files
  local env_file_paths = {
    -- current working directory
    vim.fn.getcwd() .. env_file,
    -- directory of the currently opened file
    vim.fn.expand("%:p:h") .. env_file,
  }

  -- If there's an env file in the current working dir
  for _, env_file_path in ipairs(env_file_paths) do
    if utils.file_exists(env_file_path) then
      if string.match(env_file_path, "(.-)%.json$") then
        local f = io.open(env_file_path, "r")
        if f ~= nil then
          local json_vars = f:read("*all")
          variables = vim.fn.json_decode(json_vars)
          f:close()
        end
      else
        for line in io.lines(env_file_path) do
          local vars = utils.split(line, "%s*=%s*", 1)
          variables[vars[1]] = vars[2]
        end
      end
    end
  end
  return variables
end

-- get_variables Reads the environment variables found in the env_file option
-- (defualt: .env) specified in configuration or from the files being read
-- with variables beginning with @ and returns a table with the variables
M.get_variables = function()
  local variables = {}
  local file_variables = M.get_file_variables()
  local env_variables = M.get_env_variables()
  local session_variables = M.session_variables

  for k, v in pairs(file_variables) do
    variables[k] = v
  end

  for k, v in pairs(env_variables) do
    variables[k] = v
  end

  -- override or add session variables
  for k, v in pairs(session_variables) do
    variables[k] = v
  end

  -- For each variable name
  for name, _ in pairs(variables) do
    -- For each pair of variables
    for oname, ovalue in pairs(variables) do
      -- If a variable contains another variable
      if type(variables[name]) == "string" and variables[name]:match(oname) then
        -- Add that into the variable
        -- I.E if @url={{path}}:{{port}}/{{source}}
        -- Substitue in path, port and source
        variables[name] = variables[name]:gsub("{{" .. oname .. "}}", ovalue)
      end
    end
  end

  return variables
end

M.read_dynamic_variables = function()
  local from_config = config.get("custom_dynamic_variables") or {}
  local dynamic_variables = {
    ["$uuid"] = utils.uuid,
    ["$timestamp"] = os.time,
    ["$randomInt"] = function()
      return math.random(0, 1000)
    end,
  }
  for k, v in pairs(from_config) do
    dynamic_variables[k] = v
  end
  return dynamic_variables
end

-- replace_vars replaces the env variables fields in the provided string
-- with the env variable value
-- @param str Where replace the placers for the env variables
M.replace_vars = function(str, vars)
  if vars == nil then
    vars = M.read_variables()
  end
  -- remove $dotenv tags, which are used by the vscode rest client for cross compatibility
  str = str:gsub("%$dotenv ", ""):gsub("%$DOTENV ", "")

  for var in string.gmatch(str, "{{[^}]+}}") do
    var = var:gsub("{", ""):gsub("}", "")
    -- If the env variable wasn't found in the `.env` file or in the dynamic variables then search it
    -- in the OS environment variables
    if utils.has_key(vars, var) then
      str = type(vars[var]) == "function" and str:gsub("{{" .. var .. "}}", vars[var]())
          or str:gsub("{{" .. var .. "}}", vars[var])
    else
      if os.getenv(var) then
        str = str:gsub("{{" .. var .. "}}", os.getenv(var))
      else
        error(string.format("Environment variable '%s' was not found.", var))
      end
    end
  end
  return str
end

return M
