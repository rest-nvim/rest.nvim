---@mod rest-nvim.script script runner client for rest.nvim
---
---@brief [[
---
--- Script runner client for rest.nvim.
--- This can be external module like `rest.client`
---
---@brief ]]

---@class rest.ScriptClient
local script = {}

---@param str string
---@param ctx rest.Context
function script.load_pre_req_hook(str, ctx)
    return function()
        vim.print(str, ctx)
    end
end

---@param str string
---@param ctx rest.Context
function script.load_post_req_hook(str, ctx)
    ---@param res rest.Response
    return function(res)
        vim.print(str, ctx, res)
    end
end

return script
