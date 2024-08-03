---@mod rest-nvim.result rest.nvim result buffer
---
---@brief [[
---
--- rest.nvim result buffer handling
---
---@brief ]]

local result = {}

local found_nio, nio = pcall(require, "nio")

local winbar = require("rest-nvim.result.winbar")
local logger = require("rest-nvim.logger")
local config = require("rest-nvim.config")

---Results buffer handler number
---@type number|nil
result.bufnr = nil

---Select the winbar panel based on the pane index and set the pane contents
---
---If the pane index is higher than 3 or lower than 1, it will cycle through
---the panes, e.g. >= 4 gets converted to 1 and <= 0 gets converted to 3
---@param selected number winbar pane index
function result.select_pane(selected)
  winbar.set_pane(selected)
  -- Set winbar pane contents
  ---@diagnostic disable-next-line undefined-field
  result.write_block(result.bufnr, winbar.pane_map[winbar.current_pane_index].contents, true, false)
end

---@param count number
function result.cycle_pane(count)
  local idx = winbar.current_pane_index
  result.select_pane(idx + count)
end

---Move the cursor to the desired position in the given buffer
---@param bufnr number Buffer handler number
---@param row number The desired line
---@param col number The desired column, defaults to `1`
local function move_cursor(bufnr, row, col)
  col = col or 1
  vim.api.nvim_buf_call(bufnr, function()
    vim.fn.cursor(row, col)
  end)
end

---Check if there is already a buffer with the rest run results
---and create the buffer if it does not exist
---@see vim.api.nvim_create_buf
---@return number Buffer handler number
function result.get_or_create_buf()
  local tmp_name = "rest_nvim_results"

  -- Check if the file is already loaded in the buffer
  local existing_buf, bufnr = false, nil
  for _, id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_name(id):find(tmp_name) then
      existing_buf = true
      bufnr = id
    end
  end

  if existing_buf then
    -- Set modifiable
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    -- Prevent modified flag
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
    -- Delete buffer content
    ---@cast bufnr number
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})

    -- Make sure the filetype of the buffer is `httpResult` so it will be highlighted
    vim.api.nvim_set_option_value("ft", "httpResult", { buf = bufnr })

    result.bufnr = bufnr
    return bufnr
  end

  -- Create a new buffer
  local new_bufnr = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(new_bufnr, tmp_name)
  vim.api.nvim_set_option_value("ft", "httpResult", { buf = new_bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = new_bufnr })

  result.bufnr = new_bufnr
  return new_bufnr
end

---Wrapper around `vim.api.nvim_buf_set_lines`
---@param bufnr number The target buffer
---@param block string[] The list of lines to write
---@param rewrite boolean? Rewrite the buffer content, defaults to `true`
---@param newline boolean? Add a newline to the end, defaults to `false`
---@see vim.api.nvim_buf_set_lines
function result.write_block(bufnr, block, rewrite, newline)
  rewrite = rewrite or true
  newline = newline or false

  local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local first_line = false

  if (#content == 1 and content[1] == "") or rewrite then
    first_line = true
  end

  if rewrite then
    -- Set modifiable state
    vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
    -- Delete buffer content
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  end

  vim.api.nvim_buf_set_lines(bufnr, first_line and 0 or -1, -1, false, block)

  if newline then
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "" })
  end

  -- Set unmodifiable state
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
end

---Display results buffer window
---@param bufnr number The target buffer
---@param stats table Request statistics
function result.display_buf(bufnr, stats)
  local is_result_displayed = false

  -- Check if the results buffer is already displayed
  for _, id in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(id) == bufnr then
      is_result_displayed = true
      break
    end
  end

  if not is_result_displayed then
    local cmd = "vert sb"

    local split_behavior = config.result.window
    if split_behavior.horizontal then
      cmd = "sb"
    end

    if not split_behavior.enter then
      vim.cmd(cmd .. bufnr .. " | wincmd p")
    else
      vim.cmd(cmd .. bufnr)
    end

    -- Get the ID of the window that contains the results buffer
    local winnr
    for _, id in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_buf(id) == bufnr then
        winnr = id
      end
    end

    -- Disable concealing for the results buffer window
    -- vim.api.nvim_set_option_value("conceallevel", 0, { win = winnr })

    -- Disable numbering for the results buffer window
    vim.api.nvim_set_option_value("number", false, { win = winnr })
    vim.api.nvim_set_option_value("relativenumber", false, { win = winnr })

    -- Enable wrapping and smart indent on break
    vim.api.nvim_set_option_value("wrap", true, { win = winnr })
    vim.api.nvim_set_option_value("breakindent", true, { win = winnr })

    -- Set winbar pane contents
    ---@diagnostic disable-next-line undefined-field
    result.write_block(bufnr, winbar.pane_map[winbar.current_pane_index].contents, true, false)

    -- Set unmodifiable state
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

    -- Set winbar
    winbar.set_hl() -- Set initial highlighting before displaying winbar
    vim.wo[winnr].winbar = winbar.get_content(stats)
  end

  -- Set winbar pane contents
  ---@diagnostic disable-next-line undefined-field
  result.write_block(bufnr, winbar.pane_map[winbar.current_pane_index].contents, true, false)
  move_cursor(bufnr, 1, 1)
end

---Format the result body
---@param bufnr number The target buffer
---@param headers table Request headers
---@param res table Request results
local function format_body(bufnr, headers, res)
  ---@type string
  local res_type
  for _, header in ipairs(headers) do
    if header:lower():find("^content%-type") then
      local content_type = vim.trim(vim.split(header, ":")[2])
      -- We need to remove the leading charset if we are getting a JSON
      res_type = vim.split(content_type, "/")[2]:gsub(";.*", "")
    end
  end

  -- Do not try to format binary content
  local body
  if res_type == "octet-stream" then
    body = { "Binary answer" }
  else
    local formatters = config.result.behavior.formatters
    local filetypes = vim.tbl_keys(formatters)

    -- If there is a formatter for the content type filetype then
    -- format the request result body, otherwise return it as we got it
    if vim.tbl_contains(filetypes, res_type) then
      local fmt = formatters[res_type]
      if type(fmt) == "function" then
        local ok, out = pcall(fmt, res.body)
        if ok and out then
          res.body = out
        else
          logger.error("Error calling formatter on response body:\n" .. out)
        end
      elseif vim.fn.executable(fmt) == 1 then
        local stdout = vim.fn.system(fmt, res.body):gsub("\n$", "")
        -- Check if formatter ran successfully
        if vim.v.shell_error == 0 then
          res.body = stdout
        else
          ---@diagnostic disable-next-line need-check-nil
          logger.error("Error running formatter '" .. fmt .. "' on response body:\n" .. stdout)
        end
      end
    elseif res_type ~= nil then
      ---@diagnostic disable-next-line need-check-nil
      logger.info(
        "Could not find a formatter for the body type "
          .. res_type
          .. " returned in the request, the results will not be formatted"
      )
    end

    body = vim.split(res.body, "\n")
    -- TODO: apply result.behavior.decode_url option
    table.insert(body, 1, res.method .. " " .. res.url)
    table.insert(body, 2, headers[1]) -- HTTP/X and status code + meaning
    table.insert(body, 3, "")
    table.insert(body, 4, "#+RES")
    table.insert(body, "#+END")

    -- Remove the HTTP/X and status code + meaning from here to avoid duplicates
    ---@diagnostic disable-next-line undefined-field
    table.remove(winbar.pane_map[2].contents, 1)

    -- add syntax highlights for response
    if res_type ~= nil then
      vim.api.nvim_buf_call(bufnr, function()
        local syntax_file = vim.fn.expand(string.format("$VIMRUNTIME/syntax/%s.vim", res_type))
        if vim.fn.filereadable(syntax_file) == 1 then
          vim.cmd(string.gsub(
            [[
            if exists("b:current_syntax")
              unlet b:current_syntax
            endif
            syn include @%s syntax/%s.vim
            syn region %sBody matchgroup=Comment start=+\v^#\+RES$+ end=+\v^#\+END$+ contains=@%s

            let b:current_syntax = "httpResult"
            ]],
            "%%s",
            res_type
          ))
        end
      end)
    end
  end
  ---@diagnostic disable-next-line inject-field
  winbar.pane_map[1].contents = body
end

---Write request results in the given buffer and display it
---@param bufnr number The target buffer
---@param res table Request results
function result.write_res(bufnr, res)
  local headers = vim.tbl_filter(function(header)
    if header ~= "" then
      return header
      ---@diagnostic disable-next-line missing-return
    end
  end, vim.split(res.headers, "\n"))

  local cookies = vim.tbl_filter(function(header)
    if header:lower():find("set%-cookie") then
      return header
      ---@diagnostic disable-next-line missing-return
    end
  end, headers)

  --
  -- Content-Type: application/json
  --
  ---@diagnostic disable-next-line inject-field
  winbar.pane_map[2].contents = headers

  ---@diagnostic disable-next-line inject-field
  winbar.pane_map[3].contents = vim.tbl_isempty(cookies) and { "No cookies" } or cookies

  if found_nio then
    nio.run(function()
      format_body(bufnr, headers, res)
    end)
  else
    format_body(bufnr, headers, res)
  end

  -- Add statistics to the response
  local stats = {}
  for name, stat in pairs(res.statistics) do
    local style = config.result.behavior.statistics.stats[name] or {}
    local title = style.title or name
    table.insert(stats, title .. ": " .. stat)
  end
  table.sort(stats)
  ---@diagnostic disable-next-line inject-field
  winbar.pane_map[4].contents = stats

  result.display_buf(bufnr, res.statistics)
end

return result
