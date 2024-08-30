---@mod rest-nvim.parser.curl rest.nvim curl parsing module
---
---@brief [[
---
--- rest.nvim curl command parsing module
--- rest.nvim uses `tree-sitter-bash` as a core parser to parse raw curl commands
---
---@brief ]]

local curl_parser = {}

local utils = require("rest-nvim.utils")
local logger = require("rest-nvim.logger")

---@param node TSNode Tree-sitter request node
---@param source Source
function curl_parser.parse_command(node, source)
    assert(node:type() == "command")
    assert(utils.ts_field_text(node, "name", source) == "curl")
    local arg_nodes = node:field("argument")
    if #arg_nodes < 1 then
        logger.error("can't parse curl command with 0 arguments")
        return
    end
    local args = {}
    for _, arg_node in ipairs(arg_nodes) do
        local arg_type = arg_node:type()
        if arg_type == "word" then
            table.insert(args, vim.treesitter.get_node_text(arg_node, source))
        elseif arg_type == "raw_string" then
            -- FIXME: expand escaped sequences like `\n`
            table.insert(args, vim.treesitter.get_node_text(arg_node, source):sub(2, -2))
        else
            logger.error(("can't parse argument type: '%s'"):format(arg_type))
            return
        end
    end
    return args
end

-- -X, --request
-- The request method to use.
-- -H, --header
-- The request header to include in the request.
-- -u, --user | --basic | --digest
-- The user's credentials to be provided with the request, and the authorization method to use.
-- -d, --data, --data-ascii | --data-binary | --data-raw | --data-urlencode
-- The data to be sent in a POST request.
-- -F, --form
-- The multipart/form-data message to be sent in a POST request.
-- --url
-- The URL to fetch (mostly used when specifying URLs in a config file).
-- -i, --include
-- Defines whether the HTTP response headers are included in the output.
-- -v, --verbose
-- Enables the verbose operating mode.
-- -L, --location
-- Enables resending the request in case the requested page has moved to a different location.

---@param args string[]
function curl_parser.parse_arguments(args)
    local iter = vim.iter(args)
    ---@type rest.Request
    local req = {
        -- TODO: add this to rest.Request type
        meta = {
            redirect = false,
        },
        url = "",
        method = "GET",
        headers = {},
        cookies = {},
        handlers = {},
    }
    local function any(value, list)
        return vim.list_contains(list, value)
    end
    while true do
        local arg = iter:next()
        if not arg then
            break
        end
        if any(arg, { "-X", "--request" }) then
            req.method = iter:next()
        elseif any(arg, { "-H", "--header" }) then
            local pair = iter:next()
            local key, value = pair:match("(%S+):%s*(.*)")
            if not key then
                logger.error("can't parse header:" .. pair)
            else
                key = key:lower()
                req.headers[key] = req.headers[key] or {}
                if value then
                    table.insert(req.headers[key], value)
                end
            end
        -- TODO: handle more arguments
        -- elseif any(arg, { "-u", "--user" }) then
        -- elseif arg == "--basic" then
        -- elseif arg == "--digest" then
        elseif any(arg, { "-d", "--data", "--data-ascii", "--data-raw" }) then
            -- handle external body with `@` syntax
            local body = iter:next()
            if arg ~= "--data-raw" and body:sub(1, 1) == "@" then
                req.body = {
                    __TYPE = "external",
                    data = {
                        name = "",
                        path = body:sub(2),
                    },
                }
            else
                req.body = {
                    __TYPE = "raw",
                    data = body
                }
            end
        -- elseif arg == "--data-binary" then
        -- elseif any(arg, { "-F", "--form" }) then
        elseif arg == "--url" then
            req.url = iter:next()
        elseif any(arg, { "-L", "--location" }) then
            req.meta.redirect = true
        elseif arg:match("^-%a+$") then
            local flags_iter = vim.gsplit(arg:sub(2), "")
            for flag in flags_iter do
                if flag == "L" then
                    req.meta.redirect = true
                end
            end
        elseif req.url == "" and not vim.startswith(arg, "-") then
            req.url = arg
        else
            logger.warn("unknown argument: " .. arg)
        end
    end
    return req
end

return curl_parser
