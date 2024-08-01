---@mod rest-nvim.result.winbar rest.nvim result buffer winbar add-on
---
---@brief [[
---
--- rest.nvim result buffer winbar
---
---@brief ]]

local winbar = {}

local config = require("rest-nvim.config")

---Current pane index in the results window winbar
---@type number
winbar.current_pane_index = 1

---Create the winbar contents and return them
---@param stats table Request statistics
---@return string
function winbar.get_content(stats)
  -- winbar panes
  local content =
    [[%#Normal# %1@v:lua._G._rest_nvim_winbar@%#ResponseHighlight#Response%X%#Normal# %#RestText#|%#Normal# %2@v:lua._G._rest_nvim_winbar@%#HeadersHighlight#Headers%X%#Normal# %#RestText#|%#Normal# %3@v:lua._G._rest_nvim_winbar@%#CookiesHighlight#Cookies%X%#Normal# %#RestText#|%#Normal# %4@v:lua._G._rest_nvim_winbar@%#StatsHighlight#Stats%X%#Normal# %=%<]]

  -- winbar statistics
  for stat_name, stat_value in pairs(stats) do
    local style = config.result.behavior.statistics.stats[stat_name] or {}
    if style.winbar then
      local title = type(style.winbar) == "string" and style.winbar or (style.title or stat_name):lower()
      if title ~= "" then
        title = title .. ": "
      end
      local value, representation = vim.split(stat_value, " ")[1], vim.split(stat_value, " ")[2]
      content = content .. "  %#RestText#" .. title .. "%#Number#" .. value .. " %#Normal#" .. representation
    end
  end
  content = content .. " %#RestText#|%#Normal# "
  -- content = content .. "%#RestText#Press %#Keyword#H%#RestText# for the prev pane or %#Keyword#L%#RestText# for the next pane%#Normal# "
  content = content .. "%#RestText#Press %#Keyword#?%#RestText# for help%#Normal# "

  return content
end

---@class ResultPane
---@field name string Pane name
---@field contents string[] Pane contents

---Results window winbar panes list
---@type ResultPane[]
winbar.pane_map = {
  [1] = { name = "Response", contents = { "Fetching ..." } },
  [2] = { name = "Headers", contents = { "Fetching ..." } },
  [3] = { name = "Cookies", contents = { "Fetching ..." } },
  [4] = { name = "Stats", contents = { "Fetching ..." } },
}

---Get the foreground value of a highlighting group
---@param name string Highlighting group name
---@return string
local function get_hl_group_fg(name)
  -- This will still error out if the highlight doesn't exist
  return string.format("#%06X", vim.api.nvim_get_hl(0, { name = name, link = false }).fg)
end

---Set the results window winbar highlighting groups
function winbar.set_hl()
  -- Set highlighting for the winbar panes name
  local textinfo_fg = get_hl_group_fg("Statement")
  for i, pane in ipairs(winbar.pane_map) do
    ---@diagnostic disable-next-line undefined-field
    vim.api.nvim_set_hl(0, pane.name .. "Highlight", {
      fg = textinfo_fg,
      bold = (i == winbar.current_pane_index),
      underline = (i == winbar.current_pane_index),
    })
  end

  -- Set highlighting for the winbar text
  local textmuted_fg = get_hl_group_fg("Comment")
  vim.api.nvim_set_hl(0, "RestText", { fg = textmuted_fg })
end

---Select the winbar panel based on the pane index and set the pane contents
---
---If the pane index is higher than 4 or lower than 1, it will cycle through
---the panes, e.g. >= 5 gets converted to 1 and <= 0 gets converted to 4
---@param selected number winbar pane index
function winbar.set_pane(selected)
  if type(selected) == "number" then
    winbar.current_pane_index = selected
  end

  -- Cycle through the panes
  if winbar.current_pane_index > 4 then
    winbar.current_pane_index = 1
  end
  if winbar.current_pane_index < 1 then
    winbar.current_pane_index = 4
  end

  winbar.set_hl()
end

return winbar
