---@mod rest-nvim.client rest.nvim client module
---
---@brief [[
---
--- Mainly about `rest.Client` type requirements
---
---@brief ]]

---Client to send request
---@class rest.Client
local client = {}

---Sends request and return the response asynchronously
---@param req rest.Request
---@return nio.control.Future future Future containing `rest.Response`
function client:request(req)
  local future = require("nio").control.future()
  vim.print(self, req)
  return future
end

return client
