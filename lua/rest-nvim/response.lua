local response = {}

---@class rest.Response
---@field status rest.Response.status
---@field body string?
---@field headers table<string,string[]>
---@field statistics table<string,string>

---@class rest.Response.status
---@field code number
---@field version string
---@field text string

return response
