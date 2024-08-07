---@mod rest-nvim.ui.panes Small internal library to create pane style window

---@class RestUIPane
---@field name string
---@field bufnr number
---@field group RestUIPaneGroup
---@field render fun(self:RestUIPane)

---@class RestUIPaneOpts
---@field name string
---@field on_init? fun(self:RestUIPane)
---@field render fun(self:RestUIPane):(modifiable:boolean?)

---@class RestUIPaneGroup
---@field name string
---@field panes RestUIPane[]
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
  vim.notify("`cycle()` can only be called inside the pane buffer", vim.log.levels.WARN)
end
function RestUIPaneGroup:render()
  for _, pane in ipairs(self.panes) do
    pane:render()
  end
end
function RestUIPaneGroup:enter(winnr)
  if not self.panes[1].bufnr then
    self:render()
  end
  vim.api.nvim_win_set_buf(winnr, self.panes[1].bufnr)
end

---@class RestUIPaneGroupOpts
---@field on_init? fun(self:RestUIPane)

local M = {}

---@type table<string,RestUIPaneGroup>
local groups = {}

---@param name string
---@param pane_opts RestUIPaneOpts[]
---@param opts? RestUIPaneGroupOpts
---@return RestUIPaneGroup
function M.create_pane_group(name, pane_opts, opts)
  ---@type RestUIPaneGroup
  local group = { name = name, panes = {} }
  setmetatable(group, { __index = RestUIPaneGroup })
  -- TODO: validate name doesn't conflict
  groups[name] = group
  for _, pane_opt in ipairs(pane_opts) do
    ---@type RestUIPane
    ---@diagnostic disable-next-line: missing-fields
    local pane = {
      name = pane_opt.name,
      group = group,
      render = function (self)
        if not self.bufnr then
          self.bufnr = vim.api.nvim_create_buf(false, false)
          vim.bo[self.bufnr].modifiable = false
          vim.bo[self.bufnr].swapfile = false
          vim.bo[self.bufnr].buftype = "nofile"
          vim.b[self.bufnr].__pane_group = name
          -- HACK: I can't set buffer name because it will allow `:edit` command
          -- vim.api.nvim_buf_set_name(self.bufnr, name .. "#" .. self.name)
          if opts and opts.on_init then
            opts.on_init(self)
          end
          if pane_opt.on_init then
            pane_opt.on_init(self)
          end
        end
        vim.bo[self.bufnr].modifiable = true
        local modifiable = pane_opt.render(self) or false
        if not modifiable then
          vim.bo[self.bufnr].undolevels = -1
        end
        vim.bo[self.bufnr].modifiable = modifiable
      end
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
