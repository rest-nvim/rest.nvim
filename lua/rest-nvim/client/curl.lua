---@mod rest-nvim.client.curl rest.nvim cURL client
---
---@brief [[
---
--- rest.nvim cURL client implementation
---
---@brief ]]

local client = {}

local curl = require("cURL.safe")
local mimetypes = require("mimetypes")

local utils = require("rest-nvim.utils")

-- TODO: add support for running multiple requests at once for `:Rest run document`
-- TODO: add support for submitting forms in the `client.request` function
-- TODO: add support for submitting XML bodies in the `client.request` function

---Get request statistics
---@param req table cURL request class
---@param statistics_tbl RestConfigResultStats Statistics table
---@return table
local function get_stats(req, statistics_tbl)
  local logger = _G._rest_nvim.logger

  local stats = {}

  local function get_stat(req_, stat_)
    local curl_info = curl["INFO_" .. stat_:upper()]
    if not curl_info then
      ---@diagnostic disable-next-line need-check-nil
      logger:error("The cURL request stat field '" .. stat_ "' was not found.\nPlease take a look at: https://curl.se/libcurl/c/curl_easy_getinfo.html")
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

  local stat_title, stat_info
  for _, stat in pairs(statistics_tbl) do
    for k,v in pairs(stat) do
      if type(k) == "string" and k == "title" then
        stat_title = v
      end
      if type(k) == "number" then
        stat_info = get_stat(req, v)
      end
    end
    table.insert(stats, stat_title .. " " .. stat_info)
  end

  return stats
end

---Execute an HTTP request using cURL
---@param request Request Request data to be passed to cURL
---@return table
function client.request(request)
  local logger = _G._rest_nvim.logger

  -- We have to concat request headers to a single string, e.g. ["Content-Type"]: "application/json" -> "Content-Type: application/json"
  local headers = {}
  for name, value in pairs(request.headers) do
    table.insert(headers, name .. ": " .. value)
  end

  -- Whether to skip SSL host and peer verification
  local skip_ssl_verification = _G._rest_nvim.skip_ssl_verification
  local req = curl.easy_init()
  req:setopt({
    url = request.request.url,
    -- verbose = true,
    httpheader = headers,
    ssl_verifyhost = skip_ssl_verification,
    ssl_verifypeer = skip_ssl_verification,
  })

  -- Set request HTTP version, defaults to HTTP/1.1
  if request.request.http_version then
    local http_version = request.request.http_version:gsub("%.", "_")
    req:setopt_http_version(curl["HTTP_VERSION_" .. http_version])
  else
    req:setopt_http_version(curl.HTTP_VERSION_1_1)
  end

  -- If the request method is not GET then we have to build the method in our own
  -- See: https://github.com/Lua-cURL/Lua-cURLv3/issues/156
  local method = request.request.method
  if vim.tbl_contains({ "POST", "PUT", "PATCH", "TRACE", "OPTIONS", "DELETE" }, method) then
    req:setopt_post(true)
    req:setopt_customrequest(method)
  end

  -- Request body
  if request.body.__TYPE == "json" then
    -- Create a copy of the request body table to remove the unneeded `__TYPE` metadata field
    local body = request.body
    body.__TYPE = nil

    local json_body_string = vim.json.encode(request.body)
    req:setopt_postfields(json_body_string)
  elseif request.body.__TYPE == "external_file" then
    local body_mimetype = mimetypes.guess(request.body.path)
    local post_data = {
      [request.body.name and request.body.name or "body"] = {
        file = request.body.path,
        type = body_mimetype,
      }
    }
    req:post(post_data)
  end

  -- Request execution
  local res_result = {}
  local res_headers = {}
  req:setopt_writefunction(table.insert, res_result)
  req:setopt_headerfunction(table.insert, res_headers)

  local ret = {}

  local ok, err = req:perform()
  if ok then
    -- Get request statistics if they are enabled
    local stats_config = _G._rest_nvim.result.behavior.statistics
    if stats_config.enable then
      local statistics = get_stats(req, stats_config.stats)
      ret.statistics = statistics
    end

    ret.url = req:getinfo_effective_url()
    ret.headers = table.concat(res_headers):gsub("\r", "")
    ret.result = table.concat(res_result)
  else
    ---@diagnostic disable-next-line need-check-nil
    logger:error("Something went wrong when making the request with cURL: " .. err)
  end
  req:close()

  return ret
end

return client
