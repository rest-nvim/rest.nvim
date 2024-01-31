---@mod rest-nvim.result rest.nvim result buffer
---
---@brief [[
---
--- rest.nvim result buffer handling
---
---@brief ]]

local result = {}

local nio = require("nio")

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

    return bufnr
  end

  -- Create a new buffer
  local new_bufnr = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(new_bufnr, tmp_name)
  vim.api.nvim_set_option_value("ft", "httpResult", { buf = new_bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = new_bufnr })

  return new_bufnr
end

---Wrapper around `vim.api.nvim_buf_set_lines`
---@param bufnr number The target buffer
---@param block string[] The list of lines to write
---@param newline boolean? Add a newline to the end, defaults to `false`
---@see vim.api.nvim_buf_set_lines
function result.write_block(bufnr, block, newline)
  newline = newline or false

  local content = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local first_line = false

  if #content == 1 and content[1] == "" then
    first_line = true
  end

  vim.api.nvim_buf_set_lines(bufnr, first_line and 0 or -1, -1, false, block)

  if newline then
    vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, { "" })
  end
end

function result.display_buf(bufnr)
  local is_result_displayed = false

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

    -- Set unmodifiable state
    vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
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

  -- METHOD http://foo.bar/api/endpoint
  result.write_block(bufnr, { res.method .. " " .. res.url }, true)
  -- ......
  -- Content-Type: application/json
  -- ......
  result.write_block(bufnr, headers, true)

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
    if res_type == "octet-stream" then
      -- That empty value is a newline
      local body = { "", "Binary answer" }
      result.write_block(bufnr, body, true)
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
            logger:error(
              "Error running formatter '" .. fmt .. "' on response body:\n" .. stdout
            )
          end
        end
      else
        ---@diagnostic disable-next-line need-check-nil
        logger:info(
          "Could not find a formatter for the body type " .. res_type .. " returned in the request, the results will not be formatted"
        )
      end
      local body = vim.split(res.result, "\n")
      table.insert(body, 1, "")
      table.insert(body, 2, "#+RES")
      table.insert(body, "#+END")
      result.write_block(bufnr, body, true)

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
  end)

  table.insert(res.statistics, 1, "")
  result.write_block(bufnr, res.statistics, false)

  result.display_buf(bufnr)
end

return result
