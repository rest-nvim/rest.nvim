local request = require("rest-nvim.request")
local config = require("rest-nvim.config")
local curl = require("rest-nvim.curl")
local log = require("plenary.log").new({ plugin = "rest.nvim" })

local rest = {}
local Opts = {}
local LastOpts = {}

rest.setup = function(user_configs)
  local test = config.set(user_configs or {})
  print(vim.inspect(test))
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
-- @param verbose toggles if only a dry run with preview should be executed (true = preview)
rest.run = function(verbose)
  local ok, result = request.get_current_request()
  if not ok then
    vim.api.nvim_err_writeln("[rest.nvim] Failed to get the current HTTP request: " .. result)
    return
  end

  return rest.run_request(result, { verbose = verbose })
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
-- @param string filename to load
-- @param opts table
--           1. keep_going boolean keep running even when last request failed
rest.run_file = function(filename, opts)
  log.info("Running file :" .. filename)
  local new_buf = vim.api.nvim_create_buf(false, false)

  vim.api.nvim_win_set_buf(0, new_buf)
  vim.cmd.edit(filename)
  local last_line = vim.fn.line("$")

  -- reset cursor position
  vim.fn.cursor(1, 1)
  local curpos = vim.fn.getcurpos()
  while curpos[2] <= last_line do
    local ok, req = request.buf_get_request(new_buf, curpos)
    if ok then
      -- request.print_request(req)
      curpos[2] = req.end_line + 1
      rest.run_request(req, opts)
    else
      return false, req
    end
  end
  return true
end

rest.run_request = function(req, opts)
  local result = req
  Opts = {
    method = result.method:lower(),
    url = result.url,
    -- plenary.curl can't set http protocol version
    -- http_version = result.http_version,
    headers = result.headers,
    raw = config.get("skip_ssl_verification") and vim.list_extend(result.raw, { "-k" })
      or result.raw,
    body = result.body,
    dry_run = opts.verbose,
    bufnr = result.bufnr,
    start_line = result.start_line,
    end_line = result.end_line,
  }

  if not opts.verbose then
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
    return false, req_err
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

rest.request = request

return rest
