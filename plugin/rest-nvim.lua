if vim.fn.has("nvim-0.9.0") ~= 1 then
  vim.notify_once("[rest.nvim] rest.nvim requires at least Neovim >= 0.9 in order to work")
  return
end

if vim.g.loaded_rest_nvim then
  return
end

-- NOTE: legacy code, needs an alternative later
--
-- vim.api.nvim_create_user_command('RestLog', function()
--   vim.cmd(string.format('tabnew %s', vim.fn.stdpath('cache')..'/rest.nvim.log'))
-- end, { desc = 'Opens the rest.nvim log.', })

vim.g.loaded_rest_nvim = true
