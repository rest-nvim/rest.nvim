---@mod rest-nvim.client.curl rest.nvim cURL client
---
---@brief [[
---
--- rest.nvim cURL client implementation
---
---@brief ]]

local client = {}

local curl = require("cURL.safe")

-- TODO: add support for running multiple requests at once for `:Rest run document`
-- TODO: add support for submitting forms in the `client.request` function
-- TODO: add support for submitting XML bodies in the `client.request` function

---@param request Request
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
  end

  -- Request execution
  local res_result = {}
  local res_headers = {}
  req:setopt_writefunction(table.insert, res_result)
  req:setopt_headerfunction(table.insert, res_headers)

  local ok, err = req:perform()
  if ok then
    local url = req:getinfo_effective_url()
    local code = req:getinfo_response_code()
    local content = table.concat(res_result)
    vim.print(url .. " - " .. code)
    vim.print("Request headers:", table.concat(res_headers):gsub("\r", ""))
    vim.print("Request content:\n\n" .. content)
    vim.print("\nTime taken: " .. string.format("%.2fs", req:getinfo_total_time()))
  else
    ---@diagnostic disable-next-line need-check-nil
    logger:error(err)
  end

  req:close()
end

return client
