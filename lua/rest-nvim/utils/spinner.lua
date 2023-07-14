local M = {}

local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_ns_id = vim.api.nvim_create_namespace('rest.nvim.spinner')

M.start_spinner = function(bufnr, line_number)
  vim.api.nvim_buf_clear_namespace(bufnr, spinner_ns_id, 0, -1)
  local frame_index = 1

  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, spinner_ns_id, line_number, 0, {
    virt_text = { { spinner_frames[frame_index], 'Comment' } },
  })

  local function update_spinner()
    frame_index = (frame_index % #spinner_frames) + 1
    vim.api.nvim_buf_set_extmark(bufnr, spinner_ns_id, line_number, 0, {
      id = extmark_id,
      virt_text = { { spinner_frames[frame_index], 'Comment' } },
    })
  end

  local timer = vim.loop.new_timer()
  timer:start(100, 100, vim.schedule_wrap(update_spinner))

  local stop_spinner = function(is_err)
    timer:stop()
    local result_text = { "✓", "Comment" }
    if is_err then
      result_text = { "✗", "WarningMsg" }
    end
    vim.api.nvim_buf_set_extmark(bufnr, spinner_ns_id, line_number, 0, {
      id = extmark_id,
      virt_text = { result_text },
    })
  end

  local timeout = 60000
  local timeout_timer = vim.loop.new_timer()
  timeout_timer:start(timeout, 0, function()
    timeout_timer:stop()
    vim.schedule(function() stop_spinner(true) end)
  end)

  return stop_spinner
end

return M
