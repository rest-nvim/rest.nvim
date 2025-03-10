local logger = require("rest-nvim.logger")

local function set_lines(buffer, lines)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
end

---@param buffer integer
---@param filetype string
local function syntax_highlight(buffer, filetype)
    -- manually stop any attached tree-sitter parsers (#424, #429)
    vim.treesitter.stop(buffer)
    local lang = vim.treesitter.language.get_lang(filetype)
    local ok = pcall(vim.treesitter.start, buffer, lang)
    if not lang or not ok then
        vim.bo[buffer].syntax = filetype
    end
end

---@type rest.ui.panes.PaneOpts[]
return {
    {
        name = "Response",
        render = function(self, state)
            if not state.request then
                vim.bo[self.bufnr].undolevels = -1
                set_lines(self.bufnr, { "No Request running" })
                return
            end
            syntax_highlight(self.bufnr, "rest_nvim_result")
            local lines = {
                "### " .. state.request.name,
                table.concat({ state.request.method, state.request.url, state.request.http_version }, " "),
            }
            if state.response then
                logger.debug(state.response.status)
                table.insert(
                    lines,
                    ("%s %d %s"):format(
                        state.response.status.version,
                        state.response.status.code,
                        state.response.status.text
                    )
                )
                local content_type = state.response.headers["content-type"]
                local body = vim.split(state.response.body, "\n")
                local body_meta = {}
                if content_type then
                    local base_type, res_type = content_type[1]:match("(.*)/([^;]+)")
                    -- HACK: handle application/vnd.api+json style content types
                    res_type = res_type:match(".+%+(.*)") or res_type
                    if base_type == "image" then
                        body = { "Binary(image) answer" }
                    elseif res_type == "octet_stream" then
                        body = { "Binary answer" }
                    -- elseif config.response.hooks.format then
                    --     -- NOTE: format hook runs here because it should be done last.
                    --     local ok
                    --     body, ok = utils.gq_lines(body, res_type)
                    --     if ok then
                    --         table.insert(body_meta, "formatted")
                    --     end
                    end
                end
                local meta_str = ""
                if #body_meta > 0 then
                    meta_str = " (" .. table.concat(body_meta, ",") .. ")"
                end
                table.insert(lines, "")
                table.insert(lines, "# @_RES" .. meta_str)
                vim.list_extend(lines, body)
                table.insert(lines, "# @_END")
            else
                vim.list_extend(lines, { "", "# Loading..." })
            end
            set_lines(self.bufnr, lines)
            return false
        end,
    },
    {
        name = "Headers",
        render = function(self, state)
            if not state.response then
                set_lines(self.bufnr, { "Loading..." })
                return
            end
            syntax_highlight(self.bufnr, "http_stat")
            local lines = {}
            logger.debug(state.response.headers)
            local headers = vim.iter(state.response.headers):totable()
            table.sort(headers, function(b, a)
                return a[1] > b[1]
            end)
            logger.debug(headers)
            for _, header in ipairs(headers) do
                if header[1] ~= "set-cookie" then
                    vim.list_extend(
                        lines,
                        vim.iter(header[2])
                            :map(function(value)
                                return header[1] .. ": " .. value
                            end)
                            :totable()
                    )
                end
            end
            set_lines(self.bufnr, lines)
        end,
    },
    {
        name = "Cookies",
        render = function(self, state)
            if not state.response then
                set_lines(self.bufnr, { "Loading..." })
                return
            end
            local lines = {}
            ---@type string[]?
            local cookie_headers = vim.tbl_get(state.response, "headers", "set-cookie")
            if not cookie_headers then
                set_lines(self.bufnr, { "No Cookies" })
                return
            end
            syntax_highlight(self.bufnr, "http_stat")
            table.sort(cookie_headers)
            vim.list_extend(lines, cookie_headers)
            set_lines(self.bufnr, lines)
        end,
    },
    {
        name = "Statistics",
        render = function(self, state)
            if not state.response then
                set_lines(self.bufnr, { "Loading..." })
                return
            end
            local lines = {}
            if not state.response.statistics then
                set_lines(self.bufnr, { "No Statistics" })
                return
            end
            -- TODO: use manual highlighting instead
            syntax_highlight(self.bufnr, "http_stat")
            for _, style in ipairs(require("rest-nvim.config").clients.curl.statistics) do
                local title = style.title or style.id
                local value = state.response.statistics[style.id] or ""
                table.insert(lines, ("%s: %s"):format(title, value))
            end
            set_lines(self.bufnr, lines)
        end,
    },
}
