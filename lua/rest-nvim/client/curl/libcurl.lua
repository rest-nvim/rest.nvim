---@mod rest-nvim.client.curl.libcurl rest.nvim cURL client
---
---@brief [[
---
--- rest.nvim cURL client implementation
---
---@brief ]]

local client = {}

local found_curl, curl = pcall(require, "cURL.safe")

local utils = require("rest-nvim.utils")
local logger = require("rest-nvim.logger")
local config = require("rest-nvim.config")
local curl_utils = require("rest-nvim.client.curl.utils")

-- TODO: add support for submitting forms in the `client.request` function

-- TODO: don't render statistics here. render from rest-nvim.result

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
          .. stat_("' was not found.\nPlease take a look at: https://curl.se/libcurl/c/curl_easy_getinfo.html")
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
    -- stats[name] = style.title .. " " .. get_stat(req, name)
    stats[name] = get_stat(req, name)
  end

  return stats
end

---Execute an HTTP request using cURL
---return return nil if execution failed
---@param request rest.Request Request data to be passed to cURL
---@return table? info The request information (url, method, headers, body, etc)
function client.request_(request)
  logger.info("sending request to: " .. request.url)
  -- write to `Context.response` without altering the reference
  local info = request.context.response
  if not found_curl then
    ---@diagnostic disable-next-line need-check-nil
    logger.error("lua-curl could not be found, therefore the cURL client will not work.")
    return
  end
  local host = request.headers["host"]
  if host then
    request.url = host .. request.url
  end

  -- We have to concat request headers to a single string, e.g. ["Content-Type"]: "application/json" -> "Content-Type: application/json"
  local headers = {}
  for name, value in pairs(request.headers) do
    table.insert(headers, name .. ": " .. value)
  end

  -- Whether to skip SSL host and peer verification
  local skip_ssl_verification = config.skip_ssl_verification
  local req = curl.easy_init()
  req:setopt({
    url = request.url,
    -- verbose = true,
    httpheader = headers,
    ssl_verifyhost = skip_ssl_verification,
    ssl_verifypeer = skip_ssl_verification,
  })

  -- Encode URL query parameters and set the request URL again with the encoded values
  local should_encode_url = config.encode_url
  if should_encode_url then
    -- Create a new URL as we cannot extract the URL from the req object
    local _url = curl.url()
    _url:set_url(request.url)
    -- Re-add the request query with the encoded parameters
    local query = _url:get_query()
    if type(query) == "string" then
      _url:set_query("")
      for param in vim.gsplit(query, "&") do
        _url:set_query(param, curl.U_URLENCODE + curl.U_APPENDQUERY)
      end
    end
    -- Re-add the request URL to the req object
    req:setopt_url(_url:get_url())
  end

  -- Set request HTTP version, defaults to HTTP/1.1
  if request.http_version then
    local http_version = request.http_version:gsub("%.", "_")
    req:setopt_http_version(curl["HTTP_VERSION_" .. http_version])
  else
    req:setopt_http_version(curl.HTTP_VERSION_1_1)
  end

  -- If the request method is not GET then we have to build the method in our own
  -- See: https://github.com/Lua-cURL/Lua-cURLv3/issues/156
  local method = request.method
  if vim.tbl_contains({ "POST", "PUT", "PATCH", "TRACE", "OPTIONS", "DELETE" }, method) then
    req:setopt_post(true)
    req:setopt_customrequest(method)
  end

  -- local body = vim.deepcopy(request.body)
  if request.body then
    if request.body.__TYPE == "json" then
      req:setopt_postfields(request.body.data)
    elseif request.body.__TYPE == "xml" then
      req:setopt_postfields(request.body.data)
    elseif request.body.__TYPE == "external" then
      local mimetypes = require("mimetypes")
      local body_mimetype = mimetypes.guess(request.body.data.path)
      local post_data = {
        [request.body.data.name and request.body.data.name or "body"] = {
          file = request.body.data.path,
          type = body_mimetype,
        },
      }
      req:post(post_data)
    elseif request.body.__TYPE == "form" then
      local form = curl.form()
      for k, v in pairs(request.body.data) do
        form:add_content(k, v)
      end
      req:setopt_httppost(form)
    else
      logger.error(("'%s' type body is not supported yet"):format(request.body.__TYPE))
      return
    end
  end

  -- Request execution
  local res_result = {}
  local res_headers = {}
  req:setopt_writefunction(table.insert, res_result)
  req:setopt_headerfunction(table.insert, res_headers)

  local ok, err = req:perform()
  if ok then
    -- Get request statistics if they are enabled
    local stats_config = config.result.behavior.statistics
    if stats_config.enable then
      info.statistics = get_stats(req, stats_config.stats)
    end

    info.url = req:getinfo_effective_url()
    info.code = req:getinfo_response_code()
    info.method = req:getinfo_effective_method()
    info.headers = table.concat(res_headers):gsub("\r", "")
    info.body = table.concat(res_result)
  else
    logger.error("Something went wrong when making the request with cURL:\n" .. curl_utils.curl_error(err:no()))
    return
  end
  req:close()
  return info
end

return client
