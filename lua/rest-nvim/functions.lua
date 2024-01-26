---@mod rest-nvim.functions rest.nvim functions
---
---@brief [[
---
--- rest.nvim functions
---
---@brief ]]

local functions = {}

local utils = require("rest-nvim.utils")

---Execute or `preview` one or several HTTP requests depending on given `scope`
---and return request(s) results in a table that will be used to render results
---in a buffer.
---@param scope string Defines the request execution scope. Can be: `last`, `cursor` (default) or `document`
---@param preview boolean Whether execute the request or just preview the command that is going to be ran. Default is `false`
---@return table Request results (HTTP client output)
function functions.exec(scope, preview)
  vim.validate({
    scope = { scope, "string" },
    preview = { preview, "boolean" },
  })

  -- Fallback to 'cursor' if no scope was given
  if not scope then
    scope = "cursor"
  end

  -- Raise an error if an invalid scope has been provided
  if not vim.tbl_contains({ "last", "cursor", "document" }, scope) then
    vim.notify(
      "Rest: Invalid scope '" .. scope .. "'provided to the 'exec' function",
      vim.log.levels.ERROR
    )
    return {}
  end

  print("WIP")
end

---Manage the environment file that is currently in use while running requests
---
---If you choose to `set` the environment, you must provide a `path` to the environment file.
---@param action string Determines the action to be taken. Can be: `set` or `show` (default)
function functions.env(action, path)
  vim.validate({
    action = { action, { "string", "nil" } },
    path = { path, { "string", "nil" } },
  })

  -- TODO: add a `select` action later to open some kind of prompt to select one of many detected "*env*" files
  if not action then
    action = "show"
  end

  if not vim.tbl_contains({ "set", "show" }, action) then
    vim.notify(
      "Rest: Invalid action '" .. action .. "' provided to the 'env' function",
      vim.log.levels.ERROR
    )
    return
  end

  vim.print(action)
  if action == "set" then
    -- TODO: check file path and some other goofy ahhh stuff
    if utils.file_exists(path) then
      _G._rest_nvim.env_file = path
      vim.notify("Rest: Current env file has been changed to: " .. _G._rest_nvim.env_file)
    else
      vim.notify("Rest: Passed environment file '" .. path .. "' was not found", vim.log.levels.ERROR)
    end
  else
    vim.notify("Rest: Current env file in use: " .. _G._rest_nvim.env_file)
  end
end

return functions
