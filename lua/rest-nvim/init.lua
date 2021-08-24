local rest = {}
local request = require("rest-nvim.request")
local config = require("rest-nvim.config")
local curl = require("rest-nvim.curl")
local LastOpts = {}

-- setup is needed for enabling syntax highlighting for http files
rest.setup = function(user_configs)
  config.set(user_configs or {})
  if vim.fn.expand("%:e") == "http" then
    vim.api.nvim_buf_set_option("%", "filetype", "http")
  end
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
-- @param verbose toggles if only a dry run with preview should be executed (true = preview)
rest.run = function(verbose)
  local ok, result = pcall(request.get_current_request)
  if not ok then
    vim.api.nvim_err_writeln("[rest.nvim] Failed to get the current HTTP request: " .. result)
    return
  end

  LastOpts = {
    method = result.method:lower(),
    url = result.url,
    headers = result.headers,
    raw = config.skip_ssl_verification and { "-k" } or nil,
    body = result.body,
    dry_run = verbose or false,
  }

  local success_req, req_err = pcall(curl.curl_cmd, LastOpts)

  if not success_req then
    vim.api.nvim_err_writeln(
      "[rest.nvim] Failed to perform the request.\nMake sure that you have entered the proper URL and the server is running.\n\nTraceback: "
        .. req_err
    )
  end
end

-- last will run the last curl request, if available
rest.last = function()
  if LastOpts.url == nil then
    vim.api.nvim_err_writeln("[rest.nvim]: Last request not found")
    return
  end
  local success_req, req_err = pcall(curl.curl_cmd, LastOpts)

  if not success_req then
    vim.api.nvim_err_writeln(
      "[rest.nvim] Failed to perform the request.\nMake sure that you have entered the proper URL and the server is running.\n\nTraceback: "
        .. req_err
    )
  end
end

return rest
