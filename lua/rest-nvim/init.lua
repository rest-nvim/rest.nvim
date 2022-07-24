local request = require("rest-nvim.request")
local config = require("rest-nvim.config")
local curl = require("rest-nvim.curl")

local rest = {}
local Opts = {}
local LastOpts = {}

rest.setup = function(user_configs)
  config.set(user_configs or {})
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

  Opts = {
    method = result.method:lower(),
    url = result.url,
    -- plenary.curl can't set http protocol version
    -- http_version = result.http_version,
    headers = result.headers,
    raw = config.get("skip_ssl_verification") and vim.list_extend(result.raw, { "-k" })
      or result.raw,
    body = result.body,
    dry_run = verbose or false,
    bufnr = result.bufnr,
    start_line = result.start_line,
    end_line = result.end_line,
  }

  if not verbose then
    LastOpts = Opts
  end

  if config.get("highlight").enabled then
    request.highlight(result.bufnr, result.start_line, result.end_line)
  end

  local success_req, req_err = pcall(curl.curl_cmd, Opts)

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

  if config.get("highlight").enabled then
    request.highlight(LastOpts.bufnr, LastOpts.start_line, LastOpts.end_line)
  end

  local success_req, req_err = pcall(curl.curl_cmd, LastOpts)

  if not success_req then
    vim.api.nvim_err_writeln(
      "[rest.nvim] Failed to perform the request.\nMake sure that you have entered the proper URL and the server is running.\n\nTraceback: "
        .. req_err
    )
  end
end

rest.select_env = function(path)
  if path ~= nil then
    vim.validate({ path = { path, "string" } })
    config.set({ env_file = path })
  else
    print("No path given")
  end
end

return rest
