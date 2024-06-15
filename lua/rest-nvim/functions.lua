---@mod rest-nvim.functions rest.nvim functions
---
---@brief [[
---
--- rest.nvim functions
---
---@brief ]]

local functions = {}

local found_nio, nio = pcall(require, "nio")

local utils = require("rest-nvim.utils")
local parser = require("rest-nvim.parser")
local script_vars = require("rest-nvim.parser.script_vars")

local result = require("rest-nvim.result")
local winbar = require("rest-nvim.result.winbar")

---Execute one or several HTTP requests depending on given `scope`
---and return request(s) results in a table that will be used to render results
---in a buffer.
---@param scope string Defines the request execution scope. Can be: `last`, `cursor` (default) or `document`
function functions.exec(scope)
  vim.validate({
    scope = { scope, "string" },
  })

  local api = require("rest-nvim.api")
  local env_vars = require("rest-nvim.parser.env_vars")

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
    -- Load environment variables from the env file before parsing the request
    env_vars.read_file(true)

    local req = parser.parse(
      ---@diagnostic disable-next-line param-type-mismatch
      parser.look_behind_until(parser.get_node_at_cursor(), "request")
    )

    utils.highlight(vim.api.nvim_get_current_buf(), req.start, req.end_, api.namespace)

    -- Set up a _rest_nvim_req_data Lua global table that holds the parsed request
    -- so the values can be modified from the pre-request hooks
    _G._rest_nvim_req_data = req
    -- Run pre-request hooks
    api.exec_pre_request_hooks()
    -- Clean the _rest_nvim_req_data global after running the pre-request hooks
    -- as the req table will remain modified
    _G._rest_nvim_req_data = nil

    if found_nio then
      req_results = nio
        .run(function()
          return client.request(req)
        end)
        :wait()
    else
      req_results = client.request(req)
    end

    ---Last HTTP request made by the user
    ---@type Request
    _G._rest_nvim_last_request = req
  elseif scope == "last" then
    local req = _G._rest_nvim_last_request

    if not req then
      ---@diagnostic disable-next-line need-check-nil
      logger:error("Rest run last: A previously made request was not found to be executed again")
    else
      utils.highlight(vim.api.nvim_get_current_buf(), req.start, req.end_, api.namespace)

      -- Set up a _rest_nvim_req_data Lua global table that holds the parsed request
      -- so the values can be modified from the pre-request hooks
      _G._rest_nvim_req_data = req
      -- Run pre-request hooks
      api.exec_pre_request_hooks()
      -- Clean the _rest_nvim_req_data global after running the pre-request hooks
      -- as the req table will remain modified
      _G._rest_nvim_req_data = nil

      if found_nio then
        req_results = nio
          .run(function()
            return client.request(req)
          end)
          :wait()
      else
        req_results = client.request(req)
      end
    end
  end

  -- We should not be trying to show a result or evaluate code if the request failed
  if not vim.tbl_isempty(req_results) then
    local result_buf = result.get_or_create_buf()
    result.write_res(result_buf, req_results)

    -- Load the script variables
    if not (req_results.script == "" or req_results.script == nil) then
      script_vars.load(req_results.script, req_results)
    end

    -- Set up a _rest_nvim_res_data Lua global table that holds the request results
    -- so the values can be modified from the post-request hooks
    _G._rest_nvim_res_data = req_results
    -- Run post-request hooks
    api.exec_post_request_hooks()
    -- Clean the _rest_nvim_res_data global after running the post-request hooks
    -- as the req_results table will remain modified
    _G._rest_nvim_res_data = nil
  end
end

---Find a list of environment files starting from the current directory
---@return string[] Environment variable files path
function functions.find_env_files()
  -- We are currently looking for any ".*env*" file, e.g. ".env", ".env.json"
  --
  -- This algorithm can be improved later on to search from a parent directory if the desired environment file
  -- is somewhere else but in the current working directory.
  local files = vim.fs.find(function(name, _)
    return name:match(_G._rest_nvim.env_pattern)
  end, { limit = math.huge, type = "file", path = "./" })

  return files
end

---Manage the environment file that is currently in use while running requests
---
---If you choose to `set` the environment, you must provide a `path` to the environment file.
---@param action string|nil Determines the action to be taken. Can be: `set` or `show` (default)
---@param path string|nil Path to the environment variables file
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
    ---@cast path string
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

---Cycle through the results buffer winbar panes
---@param cycle string Cycle direction, can be: `"next"` or `"prev"`
function functions.cycle_result_pane(cycle)
  ---@type number
  local idx = winbar.current_pane_index

  if cycle == "next" then
    idx = idx + 1
  elseif cycle == "prev" then
    idx = idx - 1
  end

  _G._rest_nvim_winbar(idx)
end

return functions
