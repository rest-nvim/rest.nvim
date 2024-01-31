---@mod rest-nvim.result rest.nvim result buffer
---
---@brief [[
---
--- rest.nvim result buffer handling
---
---@brief ]]

local result = {}

local nio = require("nio")

---Results buffer handler number
---@type number|nil
result.bufnr = nil

---Current pane index in the results window winbar
---@type number
result.current_pane_index = 1

---@class ResultPane
---@field name string Pane name
---@field contents string[] Pane contents

---Results window winbar panes list
---@type { [number]: ResultPane }[]
result.pane_map = {
  [1] = { name = "Response", contents = { "Fetching ..." } },
  [2] = { name = "Headers",  contents = { "Fetching ..." } },
  [3] = { name = "Cookies",  contents = { "Fetching ..." } },
}

local function get_hl_group_fg(name)
  -- If the HEX color has a zero as the first character, `string.format` will skip it
  -- so we have to add it manually later
  local hl_fg = string.format("%02X", vim.api.nvim_get_hl(0, { name = name, link = false }).fg)
  if #hl_fg == 5 then
    hl_fg = "0" .. hl_fg
  end
  hl_fg = "#" .. hl_fg
  return hl_fg
end

local function set_winbar_hl()
  -- Set highlighting for the winbar panes name
  local textinfo_fg = get_hl_group_fg("TextInfo")
  for i, pane in ipairs(result.pane_map) do
    ---@diagnostic disable-next-line undefined-field
    vim.api.nvim_set_hl(0, pane.name .. "Highlight", {
      fg = textinfo_fg,
      bold = (i == result.current_pane_index),
      underline = (i == result.current_pane_index),
    })
  end

  -- Set highlighting for the winbar stats
  local textmuted_fg = get_hl_group_fg("TextMuted")
  for _, hl in ipairs({ "Code", "Size", "Time" }) do
    vim.api.nvim_set_hl(0, "Rest" .. hl, {
      fg = textmuted_fg,
    })
  end

  -- Set highlighting for the winbar status code
  local moremsg = get_hl_group_fg("MoreMsg")
  local errormsg = get_hl_group_fg("ErrorMsg")
  local warningmsg = get_hl_group_fg("WarningMsg")
  vim.api.nvim_set_hl(0, "RestCode200", { fg = moremsg })
  vim.api.nvim_set_hl(0, "RestCode300", { fg = warningmsg })
  vim.api.nvim_set_hl(0, "RestCodexxx", { fg = errormsg })
end

local function rest_winbar(selected)
  if type(selected) == "number" then
    result.current_pane_index = selected
  end

  -- Cycle through the panes
  if result.current_pane_index > 3 then
    result.current_pane_index = 1
  end
  if result.current_pane_index < 1 then
    result.current_pane_index = 3
  end

  set_winbar_hl()
  -- Set winbar pane contents
  ---@diagnostic disable-next-line undefined-field
  result.write_block(result.bufnr, result.pane_map[result.current_pane_index].contents, true, false)
end
_G._rest_nvim_winbar = rest_winbar

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

function result.display_buf(bufnr, res_code, stats)
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

    local split_behavior = _G._rest_nvim.result.split
    if split_behavior.horizontal then
      cmd = "sb"
    elseif split_behavior.in_place then
      cmd = "bel " .. cmd
    end

    if split_behavior.stay_in_current_window_after_split then
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
    vim.api.nvim_set_option_value("conceallevel", 0, { win = winnr })

    -- Set winbar pane contents
    ---@diagnostic disable-next-line undefined-field
    result.write_block(bufnr, result.pane_map[result.current_pane_index].contents, true, false)

    -- Set unmodifiable state
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

    -- Set winbar
    --
    -- winbar panes
    local winbar = [[%#Normal# %1@v:lua._G._rest_nvim_winbar@%#ResponseHighlight#Response%X%#Normal# %2@v:lua._G._rest_nvim_winbar@%#HeadersHighlight#Headers%X%#Normal# %3@v:lua._G._rest_nvim_winbar@%#CookiesHighlight#Cookies%X%#Normal#%=%<]]

    -- winbar status code
    winbar = winbar .. "%#RestCode#" .. "status: "
    if res_code >= 200 and res_code < 300 then
      winbar = winbar .. "%#RestCode200#"
    elseif res_code >= 300 and res_code < 400 then
      winbar = winbar .. "%#RestCode300#"
    elseif res_code >= 400 then
      winbar = winbar .. "%#RestCodexxx#"
    end
    winbar = winbar .. tostring(res_code)

    -- winbar statistics
    for stat_name, stat_value in pairs(stats) do
      local val = vim.split(stat_value, ": ")
      if stat_name:find("total_time") then
        winbar = winbar .. "%#RestTime#, " .. val[1]:lower() .. ": "
        local value, representation = vim.split(val[2], " ")[1], vim.split(val[2], " ")[2]
        winbar = winbar .. "%#Number#" .. value .. " %#Normal#" .. representation
      elseif stat_name:find("size_download") then
        winbar = winbar .. "%#RestSize#, " .. val[1]:lower() .. ": "
        local value, representation = vim.split(val[2], " ")[1], vim.split(val[2], " ")[2]
        winbar = winbar .. "%#Number#" .. value .. " %#Normal#" .. representation
      end
    end
    winbar = winbar .. " "
    set_winbar_hl() -- Set initial highlighting before displaying winbar
    vim.wo[winnr].winbar = winbar
  end

  move_cursor(bufnr, 1, 1)
end

---Write request results in the given buffer and display it
---@param bufnr number The target buffer
---@param res table Request results
function result.write_res(bufnr, res)
  local logger = _G._rest_nvim.logger

  local headers = vim.tbl_filter(function(header)
    if header ~= "" then
      return header
      ---@diagnostic disable-next-line missing-return
    end
  end, vim.split(res.headers, "\n"))

  local cookies = vim.tbl_filter(function(header)
    if header:find("set%-cookie") then
      return header
      ---@diagnostic disable-next-line missing-return
    end
  end, headers)

  -- ......
  -- Content-Type: application/json
  -- ......
  ---@diagnostic disable-next-line inject-field
  result.pane_map[2].contents = headers

  ---@diagnostic disable-next-line inject-field
  result.pane_map[3].contents = vim.tbl_isempty(cookies) and { "No cookies" } or cookies

  nio.run(function()
    ---@type string
    local res_type
    for _, header in ipairs(headers) do
      if header:find("Content%-Type") then
        local content_type = vim.trim(vim.split(header, ":")[2])
        -- We need to remove the leading charset if we are getting a JSON
        res_type = vim.split(content_type, "/")[2]:gsub(";.*", "")
      end
    end

    -- Do not try to format binary content
    local body = {}
    if res_type == "octet-stream" then
      body = { "Binary answer" }
    else
      local formatters = _G._rest_nvim.result.behavior.formatters
      local filetypes = vim.tbl_keys(formatters)

      -- If there is a formatter for the content type filetype then
      -- format the request result body, otherwise return it as we got it
      if vim.tbl_contains(filetypes, res_type) then
        local fmt = formatters[res_type]
        if type(fmt) == "function" then
          local ok, out = pcall(fmt, res.result)
          if ok and out then
            res.result = out
          else
            ---@diagnostic disable-next-line need-check-nil
            logger:error("Error calling formatter on response body:\n" .. out)
          end
        elseif vim.fn.executable(fmt) == 1 then
          local stdout = vim.fn.system(fmt, res.result):gsub("\n$", "")
          -- Check if formatter ran successfully
          if vim.v.shell_error == 0 then
            res.result = stdout
          else
            ---@diagnostic disable-next-line need-check-nil
            logger:error("Error running formatter '" .. fmt .. "' on response body:\n" .. stdout)
          end
        end
      else
        ---@diagnostic disable-next-line need-check-nil
        logger:info(
          "Could not find a formatter for the body type "
            .. res_type
            .. " returned in the request, the results will not be formatted"
        )
      end
      body = vim.split(res.result, "\n")
      table.insert(body, 1, res.method .. " " .. res.url)
      table.insert(body, 2, "")
      table.insert(body, 3, "#+RES")
      table.insert(body, "#+END")
      table.insert(body, "")

      -- Add statistics to the response
      table.sort(res.statistics)
      for _, stat in pairs(res.statistics) do
        table.insert(body, stat)
      end

      -- add syntax highlights for response
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
    ---@diagnostic disable-next-line inject-field
    result.pane_map[1].contents = body
  end)

  result.display_buf(bufnr, res.code, res.statistics)
end

return result
