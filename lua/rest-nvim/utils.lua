---@mod rest-nvim.utils rest.nvim utilities
---
---@brief [[
---
--- rest.nvim utility functions
---
---@brief ]]

local logger = require("rest-nvim.logger")
-- local config = require("rest-nvim.config")

local utils = {}

-- NOTE: vim.loop has been renamed to vim.uv in Neovim >= 0.10 and will be removed later
local uv = vim.uv or vim.loop

---Encodes a string into its escaped hexadecimal representation
---@param str string Binary string to be encoded
---@param only_necessary? boolean Encode only necessary characters
---@return string
function utils.escape(str, only_necessary)
    local ignore = "%w%-%.%_%~%+"
    if only_necessary then
        ignore = ignore .. "%:%/%?%=%&%#%@"
    end
    local pattern = "([^" .. ignore .. "])"
    local encoded = string.gsub(str, pattern, function(c)
        if c == " " then
            return "+"
        end
        return string.format("%%%02x", string.byte(c))
    end)

    return encoded
end

---@param str string
function utils.url_decode(str)
    str = string.gsub(str, "%+", " ")
    str = string.gsub(str, "%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    return str
end

---Check if a file exists in the given `path`
---@param path string file path
---@return boolean
function utils.file_exists(path)
    ---@diagnostic disable-next-line undefined-field
    local fd = uv.fs_open(path, "r", 438)
    if fd then
        ---@diagnostic disable-next-line undefined-field
        uv.fs_close(fd)
        return true
    end

    return false
end

---Read a file if it exists
---@param path string file path
---@return string
function utils.read_file(path)
    ---@type string|nil
    local content
    if utils.file_exists(path) then
        ---@diagnostic disable-next-line undefined-field
        local file = uv.fs_open(path, "r", 438)
        ---@diagnostic disable-next-line undefined-field
        local stat = uv.fs_fstat(file)
        ---@diagnostic disable-next-line undefined-field
        content = uv.fs_read(file, stat.size, 0)
        ---@diagnostic disable-next-line undefined-field
        uv.fs_close(file)
    else
        ---@diagnostic disable-next-line need-check-nil
        logger.error("Failed to read file '" .. path .. "'")
        return ""
    end

    ---@cast content string
    return content
end

function utils.parse_http_time(time_str)
    local pattern = "(%a+), (%d+)[%s-](%a+)[%s-](%d+) (%d+):(%d+):(%d+) GMT"
    local _, day, month_name, year, hour, min, sec = time_str:match(pattern)
  -- stylua: ignore
  local months = {
    Jan = 1, Feb = 2, Mar = 3, Apr = 4, May = 5, Jun = 6,
    Jul = 7, Aug = 8, Sep = 9, Oct = 10, Nov = 11, Dec = 12,
  }
    local time_table = {
        year = tonumber(year),
        month = months[month_name],
        day = tonumber(day),
        hour = tonumber(hour),
        min = tonumber(min),
        sec = tonumber(sec),
        isdst = false,
    }
    ---@diagnostic disable-next-line: param-type-mismatch
    local gmt_offset = os.difftime(os.time(), os.time(os.date("!*t")))
    return os.time(time_table) + gmt_offset
end

---parse url to domain and path
---path will be fallback to "/" if not found
---@param url string
---@return string domain
---@return string path
function utils.parse_url(url)
    local domain = url:match("^%a+://([^/]+)") or url:match("^([^/]+)")
    local path = url:match("[^:/]+(/[^?#]*)") or "/"
    return domain, path
end

--- Default transformers for statistics
local transform = {
    ---Transform `time` into a readable typed time (e.g. 200ms)
    ---@param time string
    ---@return string
    time = function(time)
        ---@diagnostic disable-next-line cast-local-type
        time = tonumber(time)

        if time >= 60 then
            time = string.format("%.2f", time / 60)

            return time .. " min"
        end

        local units = { "s", "ms", "µs", "ns" }
        local unit = 1

        while time < 1 and unit < #units do
            ---@diagnostic disable-next-line cast-local-type
            time = time * 1000
            unit = unit + 1
        end

        time = string.format("%.2f", time)

        return time .. " " .. units[unit]
    end,

    ---Transform `bytes` into another bigger size type if needed
    ---@param bytes string
    ---@return string
    size = function(bytes)
        ---@diagnostic disable-next-line cast-local-type
        bytes = tonumber(bytes)

        local units = { "B", "KiB", "MiB", "GiB", "TiB", "PiB", "EiB", "ZiB", "YiB" }
        local unit = 1

        while bytes >= 1024 and unit <= #units do
            ---@diagnostic disable-next-line cast-local-type
            bytes = bytes / 1024
            unit = unit + 1
        end

        bytes = string.format("%.2f", bytes)

        return bytes .. " " .. units[unit]
    end,
}

utils.transform_time = transform.time
utils.transform_size = transform.size

---@param bufnr number
---@param node TSNode
---@param ns number
---@param timeout number
function utils.ts_highlight_node(bufnr, node, ns, timeout)
    if bufnr == 0 then
        bufnr = vim.api.nvim_get_current_buf()
    end
    local higroup = "IncSearch"
    local s_row, s_col = node:start()
    local e_row, e_col = node:end_()
    -- don't try to highlight over the last line
    if e_col == 0 then
        e_row = e_row - 1
        e_col = -1
    end
    vim.highlight.range(bufnr, ns, higroup, { s_row, s_col }, { e_row, e_col }, { regtype = "v" })

    -- Clear buffer highlights again after timeout
    vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
        end
    end, timeout)
end

---@param source string|integer
---@return vim.treesitter.LanguageTree
function utils.ts_get_parser(source)
    if type(source) == "string" then
        return vim.treesitter.get_string_parser(source, "http")
    else
        return vim.treesitter.get_parser(source, "http")
    end
end

---@param source string|integer
---@return vim.treesitter.LanguageTree
---@return TSTree
function utils.ts_parse_source(source)
    local ts_parser = utils.ts_get_parser(source)
    return ts_parser, assert(ts_parser:parse(false)[1])
end

---@param node TSNode
---@param type string
---@param oneline boolean?
---@return TSNode?
function utils.ts_find(node, type, oneline)
    if oneline then
        local sr, _, er, ec = node:range()
        local is_oneline = (sr == er) or (er - sr == 1 and ec == 0)
        if not is_oneline then
            return nil
        end
    end
    if node:type() == type then
        return node
    end
    local parent = node:parent()
    if parent then
        return utils.ts_find(parent, type)
    end
    return nil
end

---@param node TSNode
function utils.ts_upper_node(node)
    local start_row, _, _, _ = node:range()
    local end_row = start_row
    start_row = start_row - 1
    local start_col = 0
    local end_col = 0
    -- HACK: root node type might not be "document"
    local root_node = assert(utils.ts_find(node, "document"))
    local min_node = root_node:named_descendant_for_range(start_row, start_col, end_row, end_col)
    return min_node
end

---@param node TSNode
---@param expected_type string
---@return table
function utils.ts_node_spec(node, expected_type)
    return {
        node,
        function(n)
            return n:type() == expected_type
        end,
        "(" .. expected_type .. ") TSNode",
    }
end

---Create error log for TSNode that has a syntax error
---@param node TSNode Tree-sitter node
---@return string
function utils.ts_node_error_log(node)
    local s_row, s_col = node:start()
    local e_row, e_col = node:end_()
    local range = "["

    if s_row == e_row then
        range = range .. s_row .. ":" .. s_col .. " - " .. e_col
    else
        range = range .. s_row .. ":" .. s_col .. " - " .. e_row .. ":" .. e_col
    end
    range = range .. "]"
    return "The tree-sitter node at the range " .. range .. " has a syntax error and cannot be parsed"
end

---Set window-option to specific buffer
---Some options leaves in `vim.wo` while they are actually tied to buffers
---see: <https://github.com/neovim/neovim/issues/11525> and `:h local-options`
---@param bufnr number
---@param name string
---@param value any
function utils.nvim_lazy_set_wo(bufnr, name, value)
    vim.api.nvim_create_autocmd("BufWinEnter", {
        buffer = bufnr,
        callback = function()
            vim.api.nvim_set_option_value(name, value, { scope = "local" })
        end,
        once = true,
    })
end

---format lines using native vim `gq` command
---@param lines string[]
---@param filetype string
---@return string[]
---@return boolean ok Whether formatting is done with `gq`
function utils.gq_lines(lines, filetype)
    logger.debug("formatting with `gq`")
    if #lines == 0 then
        logger.debug("content is empty. Formatting is canceled")
        return lines, true
    end
    local format_buf = vim.api.nvim_create_buf(false, true)
    local ok, errmsg = pcall(vim.api.nvim_set_option_value, "filetype", filetype, { buf = format_buf })
    if not ok then
        local msg = ("Can't set filetype to '%s' (%s). Formatting is canceled"):format(filetype, errmsg)
        logger.warn(msg)
        vim.notify(msg, vim.log.levels.WARN, { title = "rest.nvim" })
        return lines, false
    end
    vim.api.nvim_buf_set_lines(format_buf, 0, -1, false, lines)
    local formatexpr = vim.bo[format_buf].formatexpr
    local formatprg = vim.bo[format_buf].formatprg
    if formatexpr:match("^v:lua%.vim%.lsp%.formatexpr%(.*%)$") then
        local clients_count = #vim.lsp.get_clients({ bufnr = format_buf })
        logger.warn(
            ("formatexpr is set to `%s` but %d clients are attached to the buffer %d."):format(
                formatexpr,
                clients_count,
                format_buf
            )
        )
        logger.warn("Skipping lsp formatexpr")
        formatexpr = ""
    end
    if formatexpr ~= "" then
        logger.debug(("formatting %s filetype with formatexpr=%s"):format(filetype, formatexpr))
    elseif formatprg ~= "" then
        logger.debug(("formatting %s filetype with formatprg=%s"):format(filetype, formatprg))
    else
        logger.debug(("can't find formatexpr or formatprg for %s filetype. Formatting is canceled"):format(filetype))
        return lines, false
    end
    vim.api.nvim_buf_call(format_buf, function()
        -- HACK: dirty fix for neovim/neovim#30593
        local gq_ok, res = pcall(vim.api.nvim_command, "silent normal gggqG")
        if not gq_ok then
            local msg = ("formatting %s filetype failed"):format(filetype)
            logger.warn(msg, res)
            vim.notify(msg, vim.log.levels.WARN, { title = "rest.nvim" })
        end
    end)
    local buf_lines = vim.api.nvim_buf_get_lines(format_buf, 0, -1, false)
    vim.api.nvim_buf_delete(format_buf, { force = true })
    return buf_lines, true
end

return utils
