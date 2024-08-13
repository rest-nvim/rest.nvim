---@mod rest-nvim.autocmds rest.nvim autocommands
---
---@brief [[
---
--- rest.nvim autocommands
---
---@brief ]]

local autocmds = {}

---Set up Rest autocommands group
function autocmds.setup()
  vim.api.nvim_create_augroup("Rest", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    pattern = "RestRequestPre",
    callback = function (_ev)
      local config = require("rest-nvim.config")
      local utils = require("rest-nvim.utils")
      local req = _G.rest_request
      if config.request.hooks.encode_url then
        req.url = utils.escape(req.url, true)
      end
    end
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "RestResponsePre",
    callback = function (_ev)
      local config = require("rest-nvim.config")
      local utils = require("rest-nvim.utils")
      local req = _G.rest_request
      local _res = _G.rest_response
      if config.response.hooks.decode_url then
        req.url = utils.url_decode(req.url)
      end
    end
  })
end

---Register a new autocommand in the `Rest` augroup
---@see vim.api.nvim_create_augroup
---@see vim.api.nvim_create_autocmd
---
---@param events string[] Autocommand events, see `:h events`
---@param cb string|fun(args: table) Autocommand lua callback, runs a Vimscript command instead if it is a `string`
---@param description string Autocommand description
---@package
function autocmds.register_autocmd(events, cb, description)
  vim.validate({
    events = { events, "table" },
    cb = { cb, { "function", "string" } },
    description = { description, "string" },
  })

  local autocmd_opts = {
    group = vim.api.nvim_create_augroup("Rest", { clear = false }),
    desc = description,
  }

  if type(cb) == "function" then
    autocmd_opts = vim.tbl_deep_extend("force", autocmd_opts, {
      callback = cb,
    })
  elseif type(cb) == "string" then
    autocmd_opts = vim.tbl_deep_extend("force", autocmd_opts, {
      command = cb,
    })
  end

  vim.api.nvim_create_autocmd(events, autocmd_opts)
end

return autocmds
