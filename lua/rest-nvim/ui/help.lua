---@mod rest-nvim.ui.help rest.nvim result buffer help
---
---@brief [[
---
--- rest.nvim result buffer help window handling
---
---@brief ]]

local help = {}

local logger = require("rest-nvim.logger")
local config = require("rest-nvim.config")

local function set_lines(buffer, lines)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
end

---Get or create a new request window help buffer
local function get_or_create_buf()
    local tmp_name = "rest_winbar_help"
    local existing_buf, help_bufnr = false, nil

    -- Check if the help buffer is already loaded
    for _, id in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_get_name(id):find(tmp_name) then
            existing_buf = true
            help_bufnr = id
        end
    end

    if not existing_buf then
        -- Create a new buffer
        local new_bufnr = vim.api.nvim_create_buf(false, true)
        local keybinds = config.ui.keybinds
        vim.api.nvim_buf_set_name(new_bufnr, tmp_name)
        vim.api.nvim_set_option_value("ft", "markdown", { buf = new_bufnr })
        vim.api.nvim_set_option_value("buftype", "nofile", { buf = new_bufnr })
        vim.keymap.set("n", "q", help.close, {
            desc = "Close rest.nvim request results help window",
            buffer = new_bufnr,
        })

        -- Write to buffer
        local buf_content = {
            "**Keybinds**:",
            "  - `" .. keybinds.prev .. "`: go to previous pane",
            "  - `" .. keybinds.next .. "`: go to next pane",
            "  - `q`: close results window",
            "",
            "**Press `q` to close this help window**",
        }
        set_lines(new_bufnr, buf_content)

        return new_bufnr
    end

    return help_bufnr
end

---Open the request results help window
function help.open()
    local help_bufnr = get_or_create_buf()

    -- Get the results buffer window ID
    local winnr = vim.api.nvim_get_current_win()

    -- Help window sizing and positioning
    local width = math.floor(vim.api.nvim_win_get_width(winnr) / 2)
    local height = 8

    local col = vim.api.nvim_win_get_width(winnr) - width - 4
    local row = vim.api.nvim_win_get_height(winnr) - height - 4

    -- Display the help buffer window
    ---@cast help_bufnr number
    local help_win = vim.api.nvim_open_win(help_bufnr, true, {
        title = "rest.nvim results window help",
        style = "minimal",
        border = "single",
        win = winnr,
        relative = "win",
        width = width,
        height = height,
        row = row,
        col = col,
    })

    -- Always conceal the markdown content
    vim.api.nvim_set_option_value("conceallevel", 2, { win = help_win })
    vim.api.nvim_set_option_value("concealcursor", "nc", { win = help_win })
end

---Close the request results help window
function help.close()
    -- Get the help buffer ID
    local winnr
    for _, id in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(id)):find("rest_winbar_help") then
            winnr = id
        end
    end

    if not winnr then
        ---@diagnostic disable-next-line need-check-nil
        logger.error("Could not find a help window to close")
        return
    end

    vim.api.nvim_win_close(winnr, false)
end

return help
