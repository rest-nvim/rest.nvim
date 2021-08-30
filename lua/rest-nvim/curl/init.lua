local utils = require("rest-nvim.utils")
local curl = require("plenary.curl")
local config = require("rest-nvim.config")
local log = require("plenary.log").new({ plugin = "rest.nvim", level = "debug" })

local M = {}
-- get_or_create_buf checks if there is already a buffer with the rest run results
-- and if the buffer does not exists, then create a new one
M.get_or_create_buf = function()
  local tmp_name = "rest_nvim_results"

  -- Check if the file is already loaded in the buffer
  local existing_bufnr = vim.fn.bufnr(tmp_name)
  if existing_bufnr ~= -1 then
    -- Set modifiable
    vim.api.nvim_buf_set_option(existing_bufnr, "modifiable", true)
    -- Prevent modified flag
    vim.api.nvim_buf_set_option(existing_bufnr, "buftype", "nofile")
    -- Delete buffer content
    vim.api.nvim_buf_set_lines(
      existing_bufnr,
      0,
      vim.api.nvim_buf_line_count(existing_bufnr) - 1,
      false,
      {}
    )

    -- Make sure the filetype of the buffer is httpResult so it will be highlighted
    vim.api.nvim_buf_set_option(existing_bufnr, "ft", "httpResult")

    return existing_bufnr
  end

  -- Create new buffer
  local new_bufnr = vim.api.nvim_create_buf(false, "nomodeline")
  vim.api.nvim_buf_set_name(new_bufnr, tmp_name)
  vim.api.nvim_buf_set_option(new_bufnr, "ft", "httpResult")
  vim.api.nvim_buf_set_option(new_bufnr, "buftype", "nofile")

  return new_bufnr
end

local function create_callback(method, url)
  return function(res)
    if res.exit ~= 0 then
      log.error("[rest.nvim] " .. utils.curl_error(res.exit))
      return
    end
    local res_bufnr = M.get_or_create_buf()
    local json_body = false

    -- Check if the content-type is "application/json" so we can format the JSON
    -- output later
    for _, header in ipairs(res.headers) do
      if string.find(header, "application/json") then
        json_body = true
        break
      end
    end

    --- Add metadata into the created buffer (status code, date, etc)
    -- Request statement (METHOD URL)
    vim.api.nvim_buf_set_lines(res_bufnr, 0, 0, false, { method:upper() .. " " .. url })

    -- HTTP version, status code and its meaning, e.g. HTTP/1.1 200 OK
    local line_count = vim.api.nvim_buf_line_count(res_bufnr)
    vim.api.nvim_buf_set_lines(
      res_bufnr,
      line_count,
      line_count,
      false,
      { "HTTP/1.1 " .. utils.http_status(res.status) }
    )
    -- Headers, e.g. Content-Type: application/json
    vim.api.nvim_buf_set_lines(
      res_bufnr,
      line_count + 1,
      line_count + 1 + #res.headers,
      false,
      res.headers
    )

    --- Add the curl command results into the created buffer
    if json_body then
      -- format JSON body
      res.body = vim.fn.system("jq", res.body)
    end
    local lines = utils.split(res.body, "\n")
    line_count = vim.api.nvim_buf_line_count(res_bufnr) - 1
    vim.api.nvim_buf_set_lines(res_bufnr, line_count, line_count + #lines, false, lines)

    -- Only open a new split if the buffer is not loaded into the current window
    if vim.fn.bufwinnr(res_bufnr) == -1 then
      local cmd_split = [[vert sb]]
      if config.result_split_horizontal == true then
        cmd_split = [[sb]]
      end
      vim.cmd(cmd_split .. res_bufnr)
      -- Set unmodifiable state
      vim.api.nvim_buf_set_option(res_bufnr, "modifiable", false)
    end

    -- Send cursor in response buffer to start
    utils.move_cursor(res_bufnr, 1)
  end
end

-- curl_cmd runs curl with the passed options, gets or creates a new buffer
-- and then the results are printed to the recently obtained/created buffer
-- @param opts curl arguments
M.curl_cmd = function(opts)
  if opts.dry_run then
    local res = curl[opts.method](opts)
    log.debug("[rest.nvim] Request preview:\n" .. "curl " .. table.concat(res, " "))
    return
  else
    opts.callback = vim.schedule_wrap(create_callback(opts.method, opts.url))
    curl[opts.method](opts)
  end
end

return M
