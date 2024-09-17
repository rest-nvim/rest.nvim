---@mod rest-nvim.client.curl.cli rest.nvim cURL cli client
---
---@brief [[
---
--- rest.nvim cURL cli client implementation
--- heavily inspired by plenary.nvim
---
---@brief ]]

local curl = {}

local nio = require("nio")
local log = require("rest-nvim.logger")
local curl_utils = require("rest-nvim.client.curl.utils")
local utils = require("rest-nvim.utils")
local config = require("rest-nvim.config")
local progress = require("fidget.progress")

---@see vim.system
---@param args string[] curl CLI arguments
---Called asynchronously when the luarocks command exits.
---Receives SystemCompleted object, see return type of SystemObj:wait().
---@param on_exit fun(sc: vim.SystemCompleted)
---@param opts? vim.SystemOpts
---@package
function curl.cli(args, on_exit, opts)
    opts = opts or {}
    opts.detach = false
    opts.text = true
    -- TODO(boltless): parse by chunk using `--trace-ascii %`
    local curl_cmd = { "curl", "-sL", "-v" }
    curl_cmd = vim.list_extend(curl_cmd, args)
    log.info(curl_cmd)
    opts.detach = false
    on_exit = vim.schedule_wrap(on_exit)
    local ok, e = pcall(vim.system, curl_cmd, opts, on_exit)
    if not ok then
        ---@type vim.SystemCompleted
        local sc = {
            code = 99999,
            signal = 0,
            stderr = "Failed to invoke curl: " .. e,
        }
        on_exit(sc)
    end
end

---@private
local parser = {}

---@package
---@param str string
---@return rest.Response.status
function parser.parse_verbose_status(str)
    local version, code, text = str:match("^(%S+) (%d+) ?(.*)")
    return {
        version = version,
        code = tonumber(code),
        text = text,
    }
end

---@package
---@param str string
---@return string? key
---@return string? value
function parser.parse_header_pair(str)
    local key, value = str:match("(%S+):(.*)")
    if not key then
        return
    end
    return key:lower(), vim.trim(value)
end

---@package
---@param line string
---@return {prefix:string,str:string?}|nil
function parser.parse_verbose_line(line)
    local prefix, str = line:match("(.) ?(.*)")
    if not prefix then
        log.error("Error while parsing verbose curl output:\n" .. line)
        return
    end
    return {
        prefix = prefix,
        str = str,
    }
end

local _VERBOSE_PREFIX_META = "*"
local _VERBOSE_PREFIX_REQ_HEADER = ">"
local _VERBOSE_PREFIX_REQ_BODY = "}"
local VERBOSE_PREFIX_RES_HEADER = "<"
-- NOTE: we don't parse response body with trace output. response body will
-- be sent to `stdout` instead of `stderr`
local _VERBOSE_PREFIX_RES_BODY = "{"
---custom prefix for statistics
local VERBOSE_PREFIX_STAT = "?"

---@package
---@param str string
function parser.parse_stat_pair(str)
    local key, value = str:match("(%S+):(.*)")
    if not key then
        return
    end
    value = vim.trim(value)
    if key:find("size") and tonumber(value) then
        log.debug("transforming stat pair as size:", key, value)
        value = utils.transform_size(value)
    elseif key:find("time") and tonumber(value) then
        log.debug("transforming stat pair as time:", key, value)
        value = utils.transform_time(value)
    end
    return key, value
end

---@param lines string[]
---@return rest.Response
function parser.parse_verbose(lines)
    local response = {
        headers = {},
        statistics = {},
    }
    vim.iter(lines):map(parser.parse_verbose_line):each(function(ln)
        if ln.prefix == VERBOSE_PREFIX_RES_HEADER then
            if not response.status then
                -- response status
                response.status = parser.parse_verbose_status(ln.str)
            else
                -- response header
                local key, value = parser.parse_header_pair(ln.str)
                if key then
                    if not response.headers[key] then
                        response.headers[key] = {}
                    end
                    table.insert(response.headers[key], value)
                end
            end
        elseif ln.prefix == VERBOSE_PREFIX_STAT then
            local key, value = parser.parse_stat_pair(ln.str)
            if key then
                response.statistics[key] = value
            end
        end
    end)
    return response
end

--- Builder ---

---@param kv table<string,string>
---@return string[]
local function kv_to_list(kv, prefix, sep)
    local tbl = {}
    for key, value in pairs(kv) do
        table.insert(tbl, prefix)
        table.insert(tbl, key .. sep .. value)
    end
    return tbl
end

---@private
local builder = {}

---@param req rest.Request
---@return string[] args
function builder.extras(req)
    local args = {}
    if config.clients.curl.opts.set_compressed then
        if
            vim.iter(req.headers):any(function(key, values)
                return key == "accept-encoding"
                    and vim.iter(values):any(function(value)
                        return value:find("gzip")
                    end)
            end)
        then
            vim.list_extend(args, { "--compressed" })
        end
    end
    return args
end

---@param method string
---@return string[] args
function builder.method(method)
    if method ~= "head" then
        return { "-X", string.upper(method) }
    else
        return { "-I" }
    end
end

---@package
---@param header table<string,string[]>
---@return string[] args
function builder.headers(header)
    local args = {}
    local upper = function(str)
        return string.gsub(" " .. str, "%W%l", string.upper):sub(2)
    end
    for key, values in pairs(header) do
        for _, value in ipairs(values) do
            vim.list_extend(args, { "-H", upper(key) .. ": " .. value })
        end
    end
    return args
end

---@param cookies rest.Cookie[]
---@return string[] args
function builder.cookies(cookies)
    return vim.iter(cookies)
        :map(function(cookie)
            return { "-b", cookie.name .. "=" .. cookie.value }
        end)
        :totable()
end

---@param body string?
---@return string[]? args
function builder.raw_body(body)
    if not body then
        return
    end
    return { "--data-raw", body }
end

---@package
---@param body table<string,string>?
---@return string[]? args
function builder.data_body(body)
    if not body then
        return
    end
    return kv_to_list(body, "-d", "=")
end

function builder.file(file)
    if not file then
        return
    end
    -- FIXME: should normalize/expand the file path
    return { "--data-binary", "@" .. file }
end

---@package
---@param version string
---@return string[]? args
function builder.http_version(version)
    vim.validate({
        version = {
            version,
            function(v)
                return not v or vim.list_contains({ "HTTP/0.9", "HTTP/1.0", "HTTP/1.1", "HTTP/2", "HTTP/3" }, v)
            end,
        },
    })
    if not version then
        return
    end
    return { "--" .. version:lower():gsub("/", "") }
end

---@return string[]? args
function builder.statistics()
    if vim.tbl_isempty(config.clients.curl.statistics) then
        return
    end
    local format = vim.iter(config.clients.curl.statistics)
        :map(function(style)
            return ("? %s:%%{%s}\n"):format(style.id, style.id)
        end)
        :join("")
    return { "-w", "%{stderr}" .. format }
end

---@package
builder.STAT_ARGS = builder.statistics()

---build curl request arguments based on Request object
---@param req rest.Request
---@param ignore_stats? boolean
---@return string[] args
function builder.build(req, ignore_stats)
    local args = {}
    ---@param list table
    ---@param value any
    local function insert(list, value)
        if value then
            table.insert(list, value)
        end
    end
    insert(args, req.url)
    insert(args, builder.extras(req))
    insert(args, builder.method(req.method))
    insert(args, builder.headers(req.headers))
    insert(args, builder.cookies(req.cookies))
    if req.body then
        if req.body.__TYPE == "external" then
            if req.body.data.content then
                insert(args, builder.raw_body(req.body.data.content))
            else
                insert(args, builder.file(req.body.data.path))
            end
        elseif req.body.__TYPE == "multipart_form_data" then
            log.error("multipart-form-data body is not supportted yet")
        elseif vim.list_contains({ "json", "xml", "raw", "graphql" }, req.body.__TYPE) then
            insert(args, builder.raw_body(req.body.data))
        else
            log.error(("unkown body type: '%s'"):format(req.body.__TYPE))
        end
    end
    if config.request.skip_ssl_verification then
        insert(args, "-k")
    end
    -- TODO: auth?
    insert(args, builder.http_version(req.http_version) or {})
    if not ignore_stats then
        insert(args, builder.STAT_ARGS)
    end
    return vim.iter(args):flatten(math.huge):totable()
end

---Generate curl command equivelant to given request.
---This command doesn't include verbose/trace options
---@param req rest.Request
function builder.build_command(req)
    local base_cmd = "curl -sL"
    local args = vim.iter(builder.build(req, true)):map(function(a)
        return vim.fn.shellescape(a)
    end)
    return base_cmd .. " " .. args:join(" ")
end

---Send request via `curl` cli
---@param request rest.Request Request data to be passed to cURL
---@return nio.control.Future future Future containing rest.Response
function curl.request(request)
    local progress_handle = progress.handle.create({
        title = "Executing",
        message = "Executing request...",
        lsp_client = { name = "rest.nvim" },
    })
    local future = nio.control.future()
    local args = builder.build(request)
    curl.cli(args, function(sc)
        if sc.code ~= 0 then
            local message = "Something went wrong when making the request with cURL:\n"
                .. curl_utils.curl_error(sc.code)
            progress_handle:cancel()
            log.error(message)
            future.set_error(message)
            return
        end
        vim.schedule(function()
            progress_handle:report({
                message = "Parsing response...",
            })
            local response = parser.parse_verbose(vim.split(sc.stderr, "\n"))
            response.body = sc.stdout
            future.set(response)
            progress_handle:report({
                message = "Success",
            })
            progress_handle:finish()
        end)
    end, {
        -- TODO(boltless): parse by chunk from here
        -- stdout = function (err, chunk) end,
        -- stderr = function (err, chunk) end,
    })
    return future
end

curl.builder = builder
curl.parser = parser

return curl
