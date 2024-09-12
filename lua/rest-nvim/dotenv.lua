---@mode rest-nvim.dotenv dotenv management module

local M = {}

local dotenv_parser = require("rest-nvim.parser.dotenv")
local config = require("rest-nvim.config")
local logger = require("rest-nvim.logger")

---load dotenv file
---This function will set environment variables in current editor session.
---@see vim.env
---@param path string file path of dotenv file
---@param setter? fun(key:string, value:string)
function M.load_file(path, setter)
    vim.validate({
        path = { path, "string" },
        settter = { setter, { "function", "nil" } },
    })
    if not setter then
        setter = function(key, value)
            vim.env[key] = value
        end
    end
    local ok = dotenv_parser.parse(path, setter)
    if not ok then
        vim.notify("failed to load file '" .. path .. "'", vim.log.levels.WARN, { title = "rest.nvim" })
    end
end

---register the dotenv file.
---this file will be sourced right before each requests (it won't be sourced
---multiple times when running all requests in current http file)
---@param path string file path of dotenv file
---@param bufnr number? buffer identifier, default to current buffer
function M.register_file(path, bufnr)
    vim.validate({
        path = {
            path,
            function(p)
                return vim.endswith(p, ".env") or vim.endswith(p, ".json")
            end,
            "`.env` or `.json` filetype",
        },
    })
    bufnr = bufnr or 0
    vim.b[bufnr]._rest_nvim_env_file = path
    vim.notify("Env file '" .. path .. "' has been registered", vim.log.levels.INFO, { title = "rest.nvim" })
end

---show registered dotenv file for current buffer
---@param bufnr number? buffer identifier, default to current buffer
function M.show_registered_file(bufnr)
    bufnr = bufnr or 0
    if not vim.b[bufnr]._rest_nvim_env_file then
        vim.notify("No env file is used in current buffer", vim.log.levels.WARN, { title = "rest.nvim" })
    else
        vim.notify(
            "Current env file in use: " .. vim.b._rest_nvim_env_file,
            vim.log.levels.INFO,
            { title = "rest.nvim" }
        )
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
        return name:match(config.env.pattern)
    end, { limit = math.huge, type = "file", path = "./" })

    return files
end

---@return string? dotenv file
function M.find_relevent_env_file()
    local filename = vim.fn.expand("%:t:r")
    if filename == "" then
        return nil
    end
    filename = filename:gsub("%.http$", "")
    ---@type string?
    local env_file
    -- search for `/same/path/filename.env`
    logger.debug("searching for " .. filename .. ".env file")
    env_file = vim.fs.find(filename .. ".env", {
        path = vim.fn.expand("%:h"),
        upward = true,
        stop = vim.fn.getcwd(),
        type = "file",
        limit = math.huge,
    })[1]
    if env_file then
        logger.debug("found .env file:", env_file)
        return env_file
    end
    -- search upward for `.env` file
    logger.debug("searching for .env file")
    env_file = vim.fs.find(function(name, _)
        return name == ".env"
    end, {
        path = vim.fn.expand("%:h"),
        upward = true,
        stop = vim.fn.getcwd(),
        type = "file",
        limit = math.huge,
    })[1]
    if env_file then
        logger.debug("found .env file:", env_file)
        return env_file
    else
        logger.debug("no .env file found")
    end
end

---@param bufnr number? buffer identifier, default to current buffer
---@return string? path
function M.select_file(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    vim.ui.select(M.find_env_files(), {
        prompt = "Select env files",
    }, function(item, _idx)
        if item then
            M.register_file(item, bufnr)
        end
    end)
end

return M
