local function set_lines(buffer, lines)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
end

---@type rest.ui.panes.PaneOpts[]
return {
    {
        name = "Headers",
        render = function(self, state)
            if not state.request then
                vim.bo[self.bufnr].undolevels = -1
                set_lines(self.bufnr, { "No Request running" })
                return
            end
            vim.bo[self.bufnr].filetype = "rest_nvim_result"
            local lines = {
                "### Request: " .. state.request.name,
                table.concat({ state.request.method, state.request.url, state.request.http_version }, " "),
                ""
            }
            if not state.response then
                table.insert(lines, "### Loading...")
                set_lines(self.bufnr, lines)
                return
            end
            table.insert(lines, "### Response")
            table.insert(
                lines,
                ("%s %d %s"):format(
                    state.response.status.version,
                    state.response.status.code,
                    state.response.status.text
                )
            )
            local headers = vim.iter(state.response.headers):totable()
            table.sort(headers, function(b, a)
                return a[1] > b[1]
            end)
            for _, header in ipairs(headers) do
                vim.list_extend(
                    lines,
                    vim.iter(header[2])
                        :map(function(value)
                            return header[1] .. ": " .. value
                        end)
                        :totable()
                )
            end
            set_lines(self.bufnr, lines)
        end,
    },
    {
        name = "Payload",
        render = function(self, state)
            if not state.request then
                set_lines(self.bufnr, { "No Request running" })
                return
            end
            -- TODO: render based on body types
            local body = state.request.body
            if not body then
                set_lines(self.bufnr, {})
                return
            end
            if vim.list_contains({ "json", "xml", "raw", "graphql" }, body.__TYPE) then
                set_lines(self.bufnr, vim.split(body.data, "\n"))
                if body.__TYPE == "graphql" then
                    vim.bo[self.bufnr].filetype = "json"
                elseif body.__TYPE ~= "raw" then
                    vim.bo[self.bufnr].filetype = body.__TYPE
                end
            elseif body.__TYPE == "multiplart_form_data" then
                -- TODO:
                set_lines(self.bufnr, { "TODO: multipart-form-data" })
            elseif body.__TYPE == "external" then
                -- TODO:
                set_lines(self.bufnr, { "TODO: external body" })
            end
        end,
    },
    {
        name = "Response",
        render = function(self, state)
            if not state.response then
                set_lines(self.bufnr, { "Loading..." })
                return
            end
            ---@type string[]
            local lines = {}
            local content_type = state.response.headers["content-type"]
            if content_type then
                local base_type, res_type = content_type[#content_type]:match("(.*)/([^;]+)")
                res_type = res_type:match(".+%+(.*)") or res_type
                if base_type == "image" then
                    table.insert(lines, "Binary(image) response")
                elseif res_type == "octet_stream" then
                    table.insert(lines, "Binary response")
                else
                    vim.bo[self.bufnr].filetype = res_type
                end
            end
            if #lines == 0 then
                lines = vim.split(state.response.body, "\n")
            end
            set_lines(self.bufnr, lines)
        end,
    },
    {
        name = "Trace",
        render = function(self, _state)
            -- TODO:
            -- TODO: use nvim_buf_add_highlights to highlight traces
            set_lines(self.bufnr, { "TODO" })
        end,
    },
}
