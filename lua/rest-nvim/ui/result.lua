---@mod rest-nvim.ui.result rest.nvim result UI module
---
---@brief [[
---
--- rest.nvim result UI implementation
---
---@brief ]]

local ui = {}

local config = require("rest-nvim.config")
local utils = require("rest-nvim.utils")
local paneui = require("rest-nvim.ui.panes")

---data used to render the UI
---@class rest.UIData
local data = {
    ---@type rest.Request?
    request = nil,
    ---@type rest.Response?
    response = nil,
}

local winbar = "%#Normal# %{%v:lua.require('rest-nvim.ui.panes').winbar()%}"
winbar = winbar .. "%=%<"
winbar = winbar .. "%{%v:lua.require('rest-nvim.ui.result').stat_winbar()%}"
winbar = winbar .. " %#RestText#|%#Normal# "
winbar = winbar .. "%#RestText#Press %#Keyword#?%#RestText# for help%#Normal# "

---Winbar component showing response statistics
---@return string
function ui.stat_winbar()
    local content = ""
    if not data.response then
        return "Loading...%#Normal#"
    end
    for _, style in ipairs(config.clients.curl.statistics) do
        if style.winbar then
            local title = type(style.winbar) == "string" and style.winbar or (style.title or style.id):lower()
            if title ~= "" then
                title = title .. ": "
            end
            local value = data.response.statistics[style.id] or ""
            content = content .. "  %#RestText#" .. title .. "%#Normal#" .. value
        end
    end
    return content
end

---@type rest.ui.panes.PaneGroup
local group = paneui.create_pane_group("rest_nvim_result", config.ui.panes, {
    on_init = function(self)
        local help = require("rest-nvim.ui.help")
        vim.keymap.set("n", config.ui.keybinds.prev, function()
            self.group:cycle(-1)
        end, { buffer = self.bufnr })
        vim.keymap.set("n", config.ui.keybinds.next, function()
            self.group:cycle(1)
        end, { buffer = self.bufnr })
        -- TODO(v4): change `?` mapping to `g?`
        vim.keymap.set("n", "?", help.open, { buffer = self.bufnr })
        vim.bo[self.bufnr].buftype = "nofile"
        if config.ui.winbar then
            utils.nvim_lazy_set_wo(self.bufnr, "winbar", winbar)
        end
    end,
})

---Check if UI window is shown in current tabpage
---@return boolean
function ui.is_open()
    local winnr = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function(id)
        local buf = vim.api.nvim_win_get_buf(id)
        return vim.b[buf].__pane_group == group.name
    end)
    return winnr ~= nil
end

---@param winnr integer
function ui.enter(winnr)
    group:enter(winnr)
end

---Clear the UI
function ui.clear()
    data = {}
    group:set_state(data)
end

---Update data and rerender the UI
---@param new_data rest.UIData
function ui.update(new_data)
    data = vim.tbl_deep_extend("force", group.state, new_data)
    group:set_state(data)
end

return ui
