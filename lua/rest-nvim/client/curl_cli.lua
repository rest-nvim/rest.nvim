local curl_cli = require("rest-nvim.client.curl.cli")

local COMPATIBLE_METHODS = {
  "OPTIONS",
  "GET",
  "HEAD",
  "POST",
  "PUT",
  "DELETE",
  "TRACE",
  "CONNECT",
  "PATCH",
  "LIST",
}

---@type rest.Client
local client = {
  name = "curl_cli",
  request = curl_cli.request,
  available = function (req)
    local method_ok = vim.list_contains(COMPATIBLE_METHODS, req.method)
    local scheme = req.url:match("^(.+)://")
    local scheme_ok = (not scheme) or scheme == "http" or scheme == "https"
    return method_ok and scheme_ok
  end
}

return client
