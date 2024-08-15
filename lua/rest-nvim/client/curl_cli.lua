local curl_cli = require("rest-nvim.client.curl.cli")

---@type rest.Client
local client = {
  request = curl_cli.request
}

return client
