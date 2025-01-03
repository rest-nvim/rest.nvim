---@mod rest-nvim.client.curl.libcurl rest.nvim cURL client using libcurl (deprecated)
---
---@brief [[
---
--- rest.nvim cURL client implementation
---
---@brief ]]

---@diagnostic disable: undefined-field

local client = {}

local found_curl, curl = pcall(require, "cURL.safe")

local utils = require("rest-nvim.utils")
local logger = require("rest-nvim.logger")
local config = require("rest-nvim.config")
local curl_utils = require("rest-nvim.client.curl.utils")
local curl_cli = require("rest-nvim.client.curl.cli")

---Get request statistics
---@param req table cURL request class
---@param statistics_tbl table Statistics table
---@return table<string,string> stats Request statistics
local function get_stats(req, statistics_tbl)
    local function get_stat(req_, stat_)
        local curl_info = curl["INFO_" .. stat_:upper()]
        if not curl_info then
            logger.error(
                "The cURL request stat field '"
                    .. stat_(
                        "' was not found.\nPlease take a look at: https://curl.se/libcurl/c/curl_easy_getinfo.html"
                    )
            )
            return
        end
        local stat_info = req_:getinfo(curl_info)

        if stat_:find("size") then
            stat_info = utils.transform_size(stat_info)
        elseif stat_:find("time") then
            stat_info = utils.transform_time(stat_info)
        end
        return stat_info
    end

    local stats = {}

    for name, _ in pairs(statistics_tbl) do
        stats[name] = get_stat(req, name)
    end

    return stats
end

---Execute an HTTP request using cURL
---return return nil if execution failed
---@param req rest.Request Request data to be passed to cURL
---@return rest.Result?
function client.request(req)
    logger.info("sending request to: " .. req.url)
    if not found_curl then
        ---@diagnostic disable-next-line need-check-nil
        logger.error("lua-curl could not be found, therefore the cURL client will not work.")
        return
    end
    local host = req.headers["host"]
    if host then
        req.url = host .. req.url
    end

    -- We have to concat request headers to a single string, e.g. ["Content-Type"]: "application/json" -> "Content-Type: application/json"
    local headers = {}
    for name, values in pairs(req.headers) do
        for _, value in ipairs(values) do
            table.insert(headers, name .. ": " .. value)
        end
    end

    -- Whether to skip SSL host and peer verification
    local skip_ssl_verification = config.skip_ssl_verification
    local req_ = curl.easy_init()
    req_:setopt({
        url = req.url,
        -- verbose = true,
        httpheader = headers,
        ssl_verifyhost = skip_ssl_verification,
        ssl_verifypeer = skip_ssl_verification,
    })

    -- Encode URL query parameters and set the request URL again with the encoded values
    local should_encode_url = config.encode_url
    if should_encode_url then
        -- Create a new URL as we cannot extract the URL from the req object
        local url_ = curl.url()
        url_:set_url(req.url)
        -- Re-add the request query with the encoded parameters
        local query = url_:get_query()
        if type(query) == "string" then
            url_:set_query("")
            for param in vim.gsplit(query, "&") do
                url_:set_query(param, curl.U_URLENCODE + curl.U_APPENDQUERY)
            end
        end
        -- Re-add the request URL to the req object
        req_:setopt_url(url_:get_url())
    end

    -- Set request HTTP version, defaults to HTTP/1.1
    if req.http_version then
        local http_version = req.http_version:gsub("%.", "_")
        req_:setopt_http_version(curl["HTTP_VERSION_" .. http_version])
    else
        req_:setopt_http_version(curl.HTTP_VERSION_1_1)
    end

    -- If the request method is not GET then we have to build the method in our own
    -- See: https://github.com/Lua-cURL/Lua-cURLv3/issues/156
    local method = req.method
    if vim.tbl_contains({ "POST", "PUT", "PATCH", "TRACE", "OPTIONS", "DELETE" }, method) then
        req_:setopt_post(true)
        req_:setopt_customrequest(method)
    end

    -- local body = vim.deepcopy(request.body)
    if req.body then
        if req.body.__TYPE == "json" then
            req_:setopt_postfields(req.body.data)
        elseif req.body.__TYPE == "xml" then
            req_:setopt_postfields(req.body.data)
        elseif req.body.__TYPE == "external" then
            local mimetypes = require("mimetypes")
            local body_mimetype = mimetypes.guess(req.body.data.path)
            local post_data = {
                [req.body.data.name and req.body.data.name or "body"] = {
                    file = req.body.data.path,
                    type = body_mimetype,
                },
            }
            req_:post(post_data)
        elseif req.body.__TYPE == "form" then
            local form = curl.form()
            for k, v in pairs(req.body.data) do
                form:add_content(k, v)
            end
            req_:setopt_httppost(form)
        else
            logger.error(("'%s' type body is not supported yet"):format(req.body.__TYPE))
            return
        end
    end

    -- Request execution
    local res_result = {}
    ---@type table<string, string[]>
    local res_raw_headers = {}
    req_:setopt_writefunction(table.insert, res_result)
    req_:setopt_headerfunction(table.insert, res_raw_headers)

    local ok, err = req_:perform()
    if not ok then
        logger.error("Something went wrong when making the request with cURL:\n" .. curl_utils.curl_error(err:no()))
        return
    end
    local status_str = table.remove(res_raw_headers, 1)
    ---@diagnostic disable-next-line: invisible
    local status = curl_cli.parser.parse_res_status(status_str)
    if not status then
        logger.error("can't parse response status:", status_str)
        return
    end
    local res_headers = {}
    for _, header in ipairs(res_raw_headers) do
        ---@diagnostic disable-next-line: invisible
        local key, value = curl_cli.parser.parse_header_pair(header)
        if key then
            if not res_headers[key] then
                res_headers[key] = {}
            end
            table.insert(res_headers[key], value)
        end
    end
    ---@type rest.Response
    local res = {
        status = status,
        headers = res_headers,
        body = table.concat(res_result),
    }
    logger.debug(vim.inspect(res.headers))
    res.status.text = vim.trim(res.status.text)
    req_:close()
    ---@type rest.Result
    return {
        requests = {
            {
                request = {
                    method = req.method,
                    url = req.url,
                    http_version = req.http_version or "HTTP/1.1",
                    headers = req.headers,
                },
                response = res,
            },
        },
        statistics = get_stats(req_, {}),
    }
end

return client
