local M = {}

local config = require("rest-nvim.config")
local utils = require("rest-nvim.utils")
local paneui = require("rest-nvim.ui.panes")
local response = require("rest-nvim.response")

local function set_lines(buffer, lines)
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
end

---@param buffer integer
---@param filetype string
local function syntax_highlight(buffer, filetype)
  local lang = vim.treesitter.language.get_lang(filetype)
  local ok = pcall(vim.treesitter.start, buffer, lang)
  if not ok then
    vim.bo[buffer].syntax = filetype
  end
end

---@type rest.ui.panes.PaneOpts[]
local panes = {
  {
    name = "Response",
    render = function(self)
      local result = response.current
      if not result then
        vim.bo[self.bufnr].undolevels = -1
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      syntax_highlight(self.bufnr, "http")
      vim.bo[self.bufnr].undolevels = 1000
      -- TODO: hmmmm how to bring request data here?
      local lines = {
        "GET" .. " " .. "TODO",
        "",
      }
      local body = response.try_format_body(result.headers["content-type"], result.body)
      vim.list_extend(lines, body)
      set_lines(self.bufnr, lines)
      return true
    end,
  },
  {
    name = "Statistics",
    render = function(self)
      local result = response.current
      if not result then
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      local lines = {}
      if not result.statistics then
        set_lines(self.bufnr, { "No Statistics" })
        return
      end
      syntax_highlight(self.bufnr, "jproperties")
      for key, value in pairs(result.statistics) do
        local skip_cookie = config.result.window.cookies and key == "set-cookies"
        if not skip_cookie then
          table.insert(lines, ("%s: %s"):format(key, value))
        end
      end
      set_lines(self.bufnr, lines)
    end,
  },
}
if config.result.window.cookies then
  table.insert(panes, 2, {
    name = "Cookies",
    render = function(self)
      local result = response.current
      if not result then
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      local lines = {}
      ---@type string?
      local cookies_raw = vim.tbl_get(result, "headers", "set-cookies")
      if not cookies_raw then
        set_lines(self.bufnr, { "No Cookies" })
        return
      end
      syntax_highlight(self.bufnr, "jproperties")
      -- TODO: parse cookies from header value, write them
      set_lines(self.bufnr, lines)
    end,
  })
end
if config.result.window.headers then
  table.insert(panes, 2, {
    name = "Headers",
    render = function(self)
      local result = response.current
      if not result then
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      syntax_highlight(self.bufnr, "jproperties")
      local lines = {}
      local headers = vim.iter(result.headers):totable()
      table.sort(headers, function(b, a) return a[1] > b[1] end)
      for _, pair in ipairs(headers) do
        table.insert(lines, ("%s: %s"):format(pair[1], pair[2]))
      end
      set_lines(self.bufnr, lines)
    end,
  })
end

local winbar = "%#Normal# %{%v:lua.require('rest-nvim.ui.panes').winbar()%}"
winbar = winbar .. "%=%<"
winbar = winbar .. "%{%v:lua.require('rest-nvim.ui.result').stat_winbar()%}"
winbar = winbar .. " %#RestText#|%#Normal# "
winbar = winbar .. "%#RestText#Press %#Keyword#?%#RestText# for help%#Normal# "
function M.stat_winbar()
  local content = ""
  local stats = vim.tbl_get(_G, "_rest_nvim_result", "statistics")
  if not stats then
    return "Loading...%#Normal#"
  end
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
  return content
end

---@type rest.ui.panes.PaneGroup
local group = paneui.create_pane_group("rest_nvim_result", panes, {
  on_init = function(self)
    local help = require("rest-nvim.ui.help")
    vim.keymap.set("n", config.result.keybinds.prev, function()
      self.group:cycle(-1)
    end, { buffer = self.bufnr })
    vim.keymap.set("n", config.result.keybinds.next, function()
      self.group:cycle(1)
    end, { buffer = self.bufnr })
    vim.keymap.set("n", "?", help.open, { buffer = self.bufnr })
    vim.bo[self.bufnr].filetype = "rest_nvim_result"
    utils.nvim_lazy_set_wo(self.bufnr, "winbar", winbar)
  end,
})

---Get the foreground value of a highlighting group
---@param name string Highlighting group name
---@return string
local function get_hl_group_fg(name)
  -- This will still error out if the highlight doesn't exist
  return string.format("#%06X", vim.api.nvim_get_hl(0, { name = name, link = false }).fg)
end

vim.api.nvim_set_hl(0, "RestText", { fg = get_hl_group_fg("Comment") })
vim.api.nvim_set_hl(0, "RestPaneTitleNC", { fg = get_hl_group_fg("Statement") })
vim.api.nvim_set_hl(0, "RestPaneTitle", {
  fg = get_hl_group_fg("Statement"),
  bold = true,
  underline = true,
})

---@param horizontal? boolean
function M.open_ui(horizontal)
  local winnr = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(function(id)
    local buf = vim.api.nvim_win_get_buf(id)
    return vim.b[buf].__pane_group == group.name
  end)
  if not winnr then
    vim.cmd.wincmd(horizontal and "s" or "v")
    group:enter(0)
    vim.cmd.wincmd("p")
  end
end

function M.update()
  group:render()
end

return M
