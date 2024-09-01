---@mod rest-nvim.logger rest.nvim logger
---
---@brief [[
---
---Logging library for rest.nvim, inspired by nvim-neorocks/rocks.nvim
---Intended for use by internal and third-party modules.
---
---@brief ]]

local logger = {}

---@type fun(...)
function logger.trace(_) end
---@type fun(...)
function logger.debug(_) end
---@type fun(...)
function logger.info(_) end
---@type fun(...)
function logger.warn(_) end
---@type fun(...)
function logger.error(_) end

local default_log_path = vim.fn.stdpath("log") --[[@as string]]

local LARGE = 1e9

local log_date_format = "%F %H:%M:%S"

---Get the rest.nvim log file path.
---@package
---@return string filepath
function logger.get_logfile()
    return vim.fs.joinpath(default_log_path, "rest-nvim.log")
end

local logfile, openerr
---@private
---Opens log file. Returns true if file is open, false on error
---@return boolean
local function open_logfile()
    -- Try to open file only once
    if logfile then
        return true
    end
    if openerr then
        return false
    end

    vim.fn.mkdir(default_log_path, "-p")
    logfile, openerr = io.open(logger.get_logfile(), "w+")
    if not logfile then
        local err_msg = string.format("Failed to open rest.nvim log file: %s", openerr)
        vim.notify(err_msg, vim.log.levels.ERROR, { title = "rest.nvim" })
        return false
    end

    local log_info = vim.uv.fs_stat(logger.get_logfile())
    if log_info and log_info.size > LARGE then
        local warn_msg =
            string.format("rest.nvim log is large (%d MB): %s", log_info.size / (1000 * 1000), logger.get_logfile())
        vim.notify(warn_msg, vim.log.levels.WARN, { title = "rest.nvim" })
    end

    -- Start message for logging
    logfile:write(string.format("[START][%s] rest.nvim logging initiated\n", os.date(log_date_format)))
    return true
end

local log_levels = vim.deepcopy(vim.log.levels)
for levelstr, levelnr in pairs(log_levels) do
    log_levels[levelnr] = levelstr
end

---Set the log level for the logger
---@param level (string|integer) New logging level
---@see vim.log.levels
function logger.set_log_level(level)
    if type(level) == "string" then
        logger.level = assert(log_levels[level:upper()], string.format("rest.nvim: Invalid log level: %q", level))
    else
        assert(log_levels[level], string.format("rest.nvim: Invalid log level: %d", level))
        logger.level = level
    end
end

for level, levelnr in pairs(vim.log.levels) do
    logger[level:lower()] = function(...)
        if logger.level == vim.log.levels.OFF or not open_logfile() then
            return false
        end
        local argc = select("#", ...)
        if levelnr < logger.level then
            return false
        end
        if argc == 0 then
            return true
        end
        local info = debug.getinfo(2, "Sl")
        local fileinfo = string.format("%s:%s", info.short_src, info.currentline)
        local parts = { level, "|", os.date(log_date_format), "|", fileinfo, "|" }
        for i = 1, argc do
            local arg = select(i, ...)
            if arg == nil then
                table.insert(parts, "<nil>")
            elseif type(arg) == "string" then
                table.insert(parts, arg)
            else
                table.insert(parts, vim.inspect(arg))
            end
        end
        logfile:write(table.concat(parts, " "), "\n")
        logfile:flush()
    end
end

logger.set_log_level(vim.tbl_get(vim.g, "rest_nvim", "_log_level") or vim.log.levels.WARN)

return logger
