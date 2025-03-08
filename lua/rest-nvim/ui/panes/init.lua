---@mod rest-nvim.ui.panes Small internal library to create pane style window

---@class rest.ui.panes.Pane
---@field name string
---@field bufnr number
---@field group rest.ui.panes.PaneGroup
---@field render fun(self:rest.ui.panes.Pane, state:any)

---@class rest.ui.panes.PaneOpts
---@field name string
---@field on_init? fun(self:rest.ui.panes.Pane)
---@field render fun(self:rest.ui.panes.Pane, state:any):(modifiable:boolean?)

---@class rest.ui.panes.PaneGroup
---@field name string
---@field panes rest.ui.panes.Pane[]
---@field state any
local RestUIPaneGroup = {}
---@param direction number
function RestUIPaneGroup:cycle(direction)
    for index, pane in ipairs(self.panes) do
        if pane.bufnr == vim.api.nvim_get_current_buf() then
            local next_index = (index + direction - 1) % #self.panes + 1
            vim.api.nvim_win_set_buf(0, self.panes[next_index].bufnr)
            return
        end
    end
    vim.notify("`cycle()` can only be called inside the pane buffer", vim.log.levels.WARN, { title = "rest.nvim" })
end
function RestUIPaneGroup:render()
    for _, pane in ipairs(self.panes) do
        pane:render(self.state)
    end
end
---@param winnr integer
function RestUIPaneGroup:enter(winnr)
    if not self.panes[1].bufnr or not vim.api.nvim_buf_is_loaded(self.panes[1].bufnr) then
        self:render()
    end
    vim.api.nvim_win_set_buf(winnr, self.panes[1].bufnr)
end
function RestUIPaneGroup:set_state(state)
    self.state = state
    self:render()
end

---@class rest.ui.panes.PaneGroupOpts
---@field on_init? fun(self:rest.ui.panes.Pane)

local M = {}

---@type table<string,rest.ui.panes.PaneGroup>
local groups = {}

---@param name string
---@param pane_opts rest.ui.panes.PaneOpts[]
---@param opts? rest.ui.panes.PaneGroupOpts
---@return rest.ui.panes.PaneGroup
function M.create_pane_group(name, pane_opts, opts)
    ---@type rest.ui.panes.PaneGroup
    local group = { name = name, panes = {} }
    setmetatable(group, { __index = RestUIPaneGroup })
    if groups[name] then
        error(("Pane group name '%s' is already taken"):format(name))
    end
    groups[name] = group
    for _, pane_opt in ipairs(pane_opts) do
        ---@type rest.ui.panes.Pane
        ---@diagnostic disable-next-line: missing-fields
        local pane = {
            name = pane_opt.name,
            group = group,
            render = function(self, state)
                if not self.bufnr or not vim.api.nvim_buf_is_loaded(self.bufnr) then
                    self.bufnr = self.bufnr or vim.api.nvim_create_buf(false, false)
                    -- small trick to ensure buffer is loaded before the `BufWinEnter` event
                    -- unless lazy-setting winbar won't work
                    vim.fn.bufload(self.bufnr)
                    vim.bo[self.bufnr].swapfile = false
                    vim.b[self.bufnr].__pane_group = name
                    vim.api.nvim_buf_set_name(self.bufnr, name .. "#" .. self.name)
                    if opts and opts.on_init then
                        opts.on_init(self)
                    end
                    if pane_opt.on_init then
                        pane_opt.on_init(self)
                    end
                end
                vim.bo[self.bufnr].modifiable = true
                local modifiable = pane_opt.render(self, state) or false
                if not modifiable then
                    vim.bo[self.bufnr].undolevels = -1
                else
                    vim.bo[self.bufnr].undolevels = vim.o.undolevels
                end
                vim.bo[self.bufnr].modifiable = modifiable
                vim.bo[self.bufnr].modified = false
            end,
        }
        table.insert(group.panes, pane)
    end
    return group
end

---@return string
function M.winbar()
    local group = groups[vim.b.__pane_group]
    if not group then
        return "not a pane buffer"
    end
    local winbar = {}
    for _, pane in ipairs(group.panes) do
        if pane.bufnr == vim.api.nvim_get_current_buf() then
            table.insert(winbar, "%#RestPaneTitle#" .. pane.name .. "%#Normal#")
        else
            table.insert(winbar, "%#RestPaneTitleNC#" .. pane.name .. "%#Normal#")
        end
    end
    return table.concat(winbar, " %#RestText#|%#Normal# ")
end

return M
