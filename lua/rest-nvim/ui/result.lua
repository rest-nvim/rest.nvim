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
  }
end

---@type rest.ui.panes.PaneOpts[]
local panes = {
  {
    name = "Response",
    render = function(self)
      if not data.request then
        vim.bo[self.bufnr].undolevels = -1
        set_lines(self.bufnr, { "No Request running" })
        return
      end
      -- HACK: `vim.treesitter.foldexpr()` finds fold based on filetype not registered parser of
      -- current buffer
      vim.bo[self.bufnr].filetype = "http"
      vim.b[self.bufnr].__rest_no_http_file = true
      -- syntax_highlight(self.bufnr, "http")
      local lines = render_request(data.request)
      if data.response then
        table.insert(lines, ("%d %s %s"):format(data.response.status.code, data.response.status.version, data.response.status.text))
        local content_type = data.response.headers["content-type"]
        table.insert(lines, "")
        table.insert(lines, "#+RES")
        ---@type string[]
        local body
        if config.response.hooks.format then
          body = res.try_format_body(content_type and content_type[1], data.response.body)
        else
          body = vim.split(data.response.body, "\n")
        end
        vim.list_extend(lines, body)
        table.insert(lines, "#+END")
      else
        vim.list_extend(lines, { "", "# Loading..." })
      end
      set_lines(self.bufnr, lines)
      return false
    end,
  },
  {
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
      for _, header in ipairs(headers) do
        if header[1] == "set-cookie" then
          vim.list_extend(lines, vim.iter(header[2]):map(function (value)
            return header[1] .. ": " .. value
          end):totable())
        end
      end
      set_lines(self.bufnr, lines)
    end,
  },
  {
    name = "Cookies",
    render = function(self)
      if not data.response then
        set_lines(self.bufnr, { "Loading..." })
        return
      end
      local lines = {}
      ---@type string[]?
      local cookie_headers = vim.tbl_get(data.response, "headers", "set-cookie")
      if not cookie_headers then
        set_lines(self.bufnr, { "No Cookies" })
        return
      end
      syntax_highlight(self.bufnr, "jproperties")
      table.sort(cookie_headers)
      vim.list_extend(lines, cookie_headers)
      set_lines(self.bufnr, lines)
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
        table.insert(lines, ("%s: %s"):format(key, value))
      end
      set_lines(self.bufnr, lines)
    end,
  },
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
  for stat_name, stat_value in pairs(data.response.statistics) do
    local style = config.clients.curl.statistics[stat_name] or {}
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
    vim.keymap.set("n", config.ui.keybinds.prev, function()
      self.group:cycle(-1)
    end, { buffer = self.bufnr })
    vim.keymap.set("n", config.ui.keybinds.next, function()
      self.group:cycle(1)
    end, { buffer = self.bufnr })
    vim.keymap.set("n", "?", help.open, { buffer = self.bufnr })
    vim.bo[self.bufnr].filetype = "rest_nvim_result"
    if config.ui.winbar then
      utils.nvim_lazy_set_wo(self.bufnr, "winbar", winbar)
    end
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
  group:render()
end

---Update data and rerender the UI
---@param new_data rest.UIData
function ui.update(new_data)
  data = vim.tbl_deep_extend("force", data, new_data)
  group:render()
end

return ui
