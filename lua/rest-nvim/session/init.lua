local config = require("rest-nvim.config")
local M = {}

M.set_env = function(key, value)
  if type(value) ~= "string" then
    print("Key ", key, " is not a string !")
  end
  local variables = M.get_env_variables()
  variables[key] = value
  -- let's not update the file for now
  M.write_env_file(variables)
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
    if M.file_exists(env_file_path) then
      local file = io.open(env_file_path, "w+")
      if file ~= nil then
        if string.match(env_file_path, "(.-)%.json$") then
          file:write(vim.fn.json_encode(variables))
        else
          for key, value in pairs(variables) do
            print("SERIALIZE key", key, value)
            file:write(key .. "=" .. tostring(value) .. "\n")
          end
        end
        file:close()
      end
    end
  end
end

return M
