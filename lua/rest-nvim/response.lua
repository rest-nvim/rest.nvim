local response = {}

local config = require("rest-nvim.config")
local logger = require("rest-nvim.logger")

---@class rest.Response
---@field status rest.Response.status
---@field body string?
---@field headers table<string,string>

---@class rest.Response.status
---@field code number
---@field version string

-- TODO: format asynchronously

---Try format the result body
---@param content_type string?
---@param body string
---@return string[]
function response.try_format_body(content_type, body)
  ---@type string
  local res_type
  if content_type then
    res_type = vim.split(content_type, "/")[2]:gsub(";.*", "")
  end
  if res_type == "octet-stream" then
    return { "Binary answer" }
  else
    local formatters = config.result.behavior.formatters
    local fmt = formatters[res_type]
    if fmt then
      if type(fmt) == "function" then
      elseif vim.fn.executable(fmt[1] or fmt) then
        local cmd = type(fmt) == "string" and { fmt } or fmt
        ---@cast cmd string[]
        local sc = vim.system(cmd, { stdin = body }):wait()
        if sc.code == 0 and sc.stdout then
          body = sc.stdout --[[@as string]]
        else
          logger.error("Error running formatter '" .. fmt .. "' on response body:\n" .. sc.stderr)
          vim.notify("Formatting response body failed. See `:Rest logs` for more info", vim.log.levels.ERROR)
        end
      end
    elseif res_type ~= nil then
      local msg = (
        "Could not find a formatter for the body type "
          .. res_type
          .. " returned in the request, the results will not be formatted"
      )
      logger.info(msg)
      vim.notify(msg, vim.log.levels.INFO)
    end
    return vim.split(body, "\n")
  end
end

return response
