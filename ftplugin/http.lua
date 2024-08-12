vim.bo.commentstring = "# %s"

vim.b._rest_nvim_count = 1

local commands = require("rest-nvim.commands")
---@diagnostic disable-next-line: invisible
commands.init(0)
