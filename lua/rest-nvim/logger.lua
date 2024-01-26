---@mod rest-nvim.logger rest.nvim logger
---
---@brief [[
---
---Logging library for rest.nvim, slightly inspired by rmagatti/logger.nvim
---Intended for use by internal and third-party modules.
---
---Default logger instance is made during the `setup` and can be accessed
---by anyone through the `_G._rest_nvim.logger` configuration field
---that is set automatically.
---
---------------------------------------------------------------------------------
---
---Usage:
---
---```lua
---local logger = require("rest-nvim.logger"):new({ level = "debug" })
---
---logger:set_log_level("info")
---
---logger:info("This is an info log")
--- -- [rest.nvim] INFO: This is an info log
---```
---
---@brief ]]

---@class Logger
local logger = {}

-- NOTE: vim.loop has been renamed to vim.uv in Neovim >= 0.10 and will be removed later
local uv = vim.uv or vim.loop

---@see vim.log.levels
---@class LoggerLevels
local levels = {
  trace = vim.log.levels.TRACE,
  debug = vim.log.levels.DEBUG,
  info = vim.log.levels.INFO,
  warn = vim.log.levels.WARN,
  error = vim.log.levels.ERROR,
}

---@class LoggerConfig
---@field level_name string Logging level name. Default is `"info"`
---@field save_logs boolean Whether to save log messages into a `.log` file. Default is `true`
local default_config = {
  level_name = "info",
  save_logs = true,
}

---Store the logger output in a file at `vim.fn.stdpath("log")`
---@see vim.fn.stdpath
---@param msg string Logger message to be saved
local function store_log(msg)
  local date = os.date("%F %r") -- 2024-01-26 01:25:05 PM
  local log_msg = date .. " | " .. msg
  local log_path = vim.fs.joinpath(vim.fn.stdpath("log"), "rest.nvim.log")

  -- 644 sets read and write permissions for the owner, and it sets read-only
  -- mode for the group and others
  uv.fs_open(log_path, "a+", tonumber(644, 8), function(err, file)
    if file and not err then
      local file_pipe = uv.new_pipe(false)
      ---@cast file_pipe uv_pipe_t
      uv.pipe_open(file_pipe, file)
      uv.write(file_pipe, log_msg)
      uv.fs_close(file)
    end
  end)
end

---Create a new logger instance
---@param opts LoggerConfig Logger configuration
---@return Logger
function logger:new(opts)
  opts = opts or {}
  local conf = vim.tbl_deep_extend("force", default_config, opts)
  self.level = levels[conf.level_name]
  self.save_logs = conf.save_logs

  self.__index = function(_, index)
    if type(self[index]) == "function" then
      return function(...)
        -- Make any logger function call with "." access result in the syntactic sugar ":" access
        self[index](self, ...)
      end
    else
      return self[index]
    end
  end
  setmetatable(opts, self)

  return self
end

---Set the log level for the logger
---@param level string New logging level
---@see vim.log.levels
function logger:set_log_level(level)
  self.level = levels[level]
end

---Log a trace message
---@param msg string Log message
function logger:trace(msg)
  msg = "[rest.nvim] TRACE: " .. msg
  if self.level == vim.log.levels.TRACE then
    vim.notify(msg, levels.trace)
  end

  if self.save_logs then
    store_log(msg)
  end
end

---Log a debug message
---@param msg string Log message
function logger:debug(msg)
  msg = "[rest.nvim] DEBUG: " .. msg
  if self.level == vim.log.levels.DEBUG then
    vim.notify(msg, levels.debug)
  end

  if self.save_logs then
    store_log(msg)
  end
end

---Log an info message
---@param msg string Log message
function logger:info(msg)
  msg = "[rest.nvim] INFO: " .. msg
  local valid_levels = { vim.log.levels.INFO, vim.log.levels.DEBUG }
  if vim.tbl_contains(valid_levels, self.level) then
    vim.notify(msg, levels.info)
  end

  if self.save_logs then
    store_log(msg)
  end
end

---Log a warning message
---@param msg string Log message
function logger:warn(msg)
  msg = "[rest.nvim] WARN: " .. msg
  local valid_levels = { vim.log.levels.INFO, vim.log.levels.DEBUG, vim.log.levels.WARN }
  if vim.tbl_contains(valid_levels, self.level) then
    vim.notify(msg, levels.warn)
  end

  if self.save_logs then
    store_log(msg)
  end
end

---Log an error message
---@param msg string Log message
function logger:error(msg)
  msg = "[rest.nvim] ERROR: " .. msg
  vim.notify(msg, levels.error)

  if self.save_logs then
    store_log(msg)
  end
end

return logger
