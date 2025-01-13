vim.bo.commentstring = "# %s"
vim.wo.conceallevel = 0
vim.opt.comments:remove("n:>")

-- NOTE: Manually start tree-sitter-http highlighting.
-- Just in case user didn't enabled auto highlighting option.
local ok = pcall(vim.treesitter.start, 0, "http")
if not ok then
    vim.notify("Failed to attach tree-sitter-http parser to current buffer", vim.log.levels.ERROR, { title = "rest.nvim" })
end

local dotenv = require("rest-nvim.dotenv")

vim.b._rest_nvim_count = 1
vim.b._rest_nvim_env_file = dotenv.find_relevent_env_file()
