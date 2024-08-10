local ui = {}

local config = require("rest-nvim.config")
local utils = require("rest-nvim.utils")
local paneui = require("rest-nvim.ui.panes")
local res = require("rest-nvim.response")

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

---@class rest.UIData
local data = {
  ---@type rest.Request?
  request = nil,
  ---@type rest.Response?
  response = nil
}

---@param req rest.Request
---@return string[]
local function render_request(req)
  local req_line = req.method .. " " .. req.url
  if req.http_version then
    req_line = req_line .. " " .. req.http_version
  end
  return {
    "### " .. req.name,
    req_line,
    ""
  }
end

---@type rest.ui.panes.PaneOpts[]
local panes = {
  {
    name = "Response",
    render = function(self)
      if not data.request then
        vim.bo[self.bufnr].undolevels = -1
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      -- HACK: `vim.treesitter.foldexpr()` finds fold based on filetype not registered parser of
      -- current buffer
      vim.bo[self.bufnr].filetype = "http"
      vim.b[self.bufnr].__rest_no_http_file = true
      -- syntax_highlight(self.bufnr, "http")
      local lines = render_request(data.request)
      if data.response then
        local body = res.try_format_body(data.response.headers["content-type"], data.response.body)
        table.insert(lines, "#+RES")
        vim.list_extend(lines, body)
        table.insert(lines, "#+END")
      else
        vim.list_extend(lines, { "# Loading..." })
      end
      set_lines(self.bufnr, lines)
      return false
    end,
  },
  {
    name = "Statistics",
    render = function(self)
      if not data.response then
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      local lines = {}
      if not data.response.statistics then
        set_lines(self.bufnr, { "No Statistics" })
        return
      end
      syntax_highlight(self.bufnr, "jproperties")
      for key, value in pairs(data.response.statistics) do
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
      if not data.response then
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      local lines = {}
      ---@type string?
      local cookies_raw = vim.tbl_get(data.response, "headers", "set-cookies")
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
      if not data.response then
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      syntax_highlight(self.bufnr, "jproperties")
      local lines = {}
      local headers = vim.iter(data.response.headers):totable()
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
function ui.stat_winbar()
  local content = ""
  if not data.response then
    return "Loading...%#Normal#"
  end
  for stat_name, stat_value in pairs(data.response.statistics) do
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
function ui.open_ui(horizontal)
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

function ui.clear()
  data = {}
  group:render()
end

---@param new_data rest.UIData
function ui.update(new_data)
  data = vim.tbl_deep_extend("force", data, new_data)
  group:render()
end

return ui
