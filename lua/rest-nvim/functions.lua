---@mod rest-nvim.functions rest.nvim functions
---
---@brief [[
---
--- rest.nvim functions
---
---@brief ]]

local functions = {}

local nio = require("nio")
local utils = require("rest-nvim.utils")
local parser = require("rest-nvim.parser")
local result = require("rest-nvim.result")

---Execute one or several HTTP requests depending on given `scope`
---and return request(s) results in a table that will be used to render results
---in a buffer.
---@param scope string Defines the request execution scope. Can be: `last`, `cursor` (default) or `document`
function functions.exec(scope)
  vim.validate({
    scope = { scope, "string" },
  })

  local logger = _G._rest_nvim.logger
  local ok, client = pcall(require, "rest-nvim.client." .. _G._rest_nvim.client)
  if not ok then
    ---@diagnostic disable-next-line need-check-nil
    logger:error("The client '" .. _G._rest_nvim.client .. "' could not be found. Maybe it is not installed?")
    return {}
  end

  -- Fallback to 'cursor' if no scope was given
  if not scope then
    scope = "cursor"
  end

  -- Raise an error if an invalid scope has been provided
  if not vim.tbl_contains({ "last", "cursor", "document" }, scope) then
    ---@diagnostic disable-next-line need-check-nil
    logger:error("Invalid scope '" .. scope .. "' provided to the 'exec' function")
    return {}
  end

  -- TODO: implement `document` scope.
  --
  -- NOTE: The `document` scope may require some parser adjustments
  local req_results = {}

  if scope == "cursor" then
    local req = parser.parse(
      ---@diagnostic disable-next-line param-type-mismatch
      parser.look_behind_until(parser.get_node_at_cursor(), "request")
    )

    req_results = nio
      .run(function()
        return client.request(req)
      end)
      :wait()

    ---Last HTTP request made by the user
    ---@type Request
    _G._rest_nvim_last_request = req
  elseif scope == "last" then
    local req = _G._rest_nvim_last_request

    if not req then
      ---@diagnostic disable-next-line need-check-nil
      logger:error("Rest run last: A previously made request was not found to be executed again")
    else
      req_results = nio
        .run(function()
          return client.request(req)
        end)
        :wait()
    end
  end

  local result_buf = result.get_or_create_buf()
  result.write_res(result_buf, req_results)
end

---Find a list of environment files starting from the current directory
---@return string[]
function functions.find_env_files()
  -- We are currently looking for any ".*env*" file, e.g. ".env", ".env.json"
  --
  -- This algorithm can be improved later on to search from a parent directory if the desired environment file
  -- is somewhere else but in the current working directory.
  local files = vim.fs.find(function(name, path)
    return name:match(".*env.*$")
  end, { limit = math.huge, type = "file", path = "./" })

  return files
end

---Manage the environment file that is currently in use while running requests
---
---If you choose to `set` the environment, you must provide a `path` to the environment file.
---@param action string Determines the action to be taken. Can be: `set` or `show` (default)
function functions.env(action, path)
  -- TODO: add a `select` action later to open some kind of prompt to select one of many detected "*env*" files
  vim.validate({
    action = { action, { "string", "nil" } },
    path = { path, { "string", "nil" } },
  })

  local logger = _G._rest_nvim.logger

  if not action then
    action = "show"
  end

  if not vim.tbl_contains({ "set", "show" }, action) then
    ---@diagnostic disable-next-line need-check-nil
    logger:error("Invalid action '" .. action .. "' provided to the 'env' function")
    return
  end

  if action == "set" then
    if utils.file_exists(path) then
      _G._rest_nvim.env_file = path
      ---@diagnostic disable-next-line need-check-nil
      logger:info("Current env file has been changed to: " .. _G._rest_nvim.env_file)
    else
      ---@diagnostic disable-next-line need-check-nil
      logger:error("Passed environment file '" .. path .. "' was not found")
    end
  else
    ---@diagnostic disable-next-line need-check-nil
    logger:info("Current env file in use: " .. _G._rest_nvim.env_file)
  end
end

return functions
