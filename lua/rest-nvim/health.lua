---@mod rest-nvim.health rest.nvim healthcheck
---
---@brief [[
---
---Healthcheck module for rest.nvim
---
---@brief ]]

local health = {}

local function install_health()
    vim.health.start("Installation")

    -- Luarocks installed
    -- we check for either luarocks system-wide or rocks.nvim as rocks.nvim can manage Luarocks installation
    -- and also luarocks.nvim in case the end-user is using lazy.nvim
    local found_luarocks_nvim = package.searchpath("luarocks", package.path)

    if vim.fn.executable("luarocks") ~= 1 and not vim.g.rocks_nvim_loaded and not found_luarocks_nvim then
        vim.health.warn(
            "`Luarocks` is not installed in your system",
            "Are you sure you installed all needed dependencies properly?"
        )
    else
        vim.health.ok("Found `luarocks` installed in your system")
    end

    -- Luarocks in `package.path`
    local found_luarocks_in_path = string.find(package.path, "rocks")
    if not found_luarocks_in_path then
        vim.health.error(
            "Luarocks PATHs were not found in your Neovim's Lua `package.path`",
            "Check rest.nvim README to know how to add your luarocks PATHs to Neovim"
        )
    else
        vim.health.ok("Found Luarocks PATHs in your Neovim's Lua `package.path`")
    end

    -- Luarocks dependencies existence checking
    for dep, dep_info in pairs(vim.g.rest_nvim_deps) do
        if not dep_info.found then
            local err_advice = "Install it through `luarocks --local --lua-version=5.1 install " .. dep .. "`"
            if dep:find("nvim") then
                err_advice = "Install it through your preferred plugins manager or luarocks by using `luarocks --local --lua-version=5.1 install "
                    .. dep
                    .. "`"
            end

            vim.health.error("Dependency `" .. dep .. "` was not found (" .. dep_info.error .. ")", err_advice)
        else
            vim.health.ok("Dependency `" .. dep .. "` was found")
        end
    end
end

local function formatter_health()
    vim.health.start("Response body formatters")

    -- Formatter checking
    for _, ft in ipairs({ "json", "xml", "html" }) do
        local formatexpr = vim.api.nvim_get_option_value("formatexpr", { filetype = ft })
        local formatprg = vim.api.nvim_get_option_value("formatprg", { filetype = ft })
        if formatexpr == "" and formatprg == "" then
            vim.health.warn("Options 'formatexpr' or 'formatprg' are not set for " .. ft .. " filetype")
        else
            if formatexpr ~= "" then
                vim.health.ok(("Option 'formatexpr' is set to `%s` for %s filetype"):format(formatexpr, ft))
            else
                vim.health.ok(("Option 'formatprg' is set to `%s` for %s filetype"):format(formatexpr, ft))
            end
        end
    end
    vim.health.info("You can set formatter for each filetype via 'formatexpr' or 'formatprg' option")
end

-- TODO: check if http parser exist (it may not exist in rtp but registered manually)
local function parser_health()
    vim.health.start("tree-sitter parsers")
    local parser = vim.api.nvim_get_runtime_file('parser/http.so', true)[1]
    local parsername = vim.fn.fnamemodify(parser, ':t:r')
    local is_loadable, err_or_nil = pcall(vim.treesitter.language.add, parsername)

    if not is_loadable then
        vim.health.error(
            string.format(
                'Parser "%s" failed to load (path: %s): %s',
                parsername,
                parser,
                err_or_nil or '?'
            )
        )
    else
        local lang = vim.treesitter.language.inspect(parsername)
        vim.health.ok(
            string.format('Parser: %-20s ABI: %d, path: %s', parsername, lang._abi_version, parser)
        )
    end
end

function health.check()
    install_health()
    formatter_health()
    parser_health()
end

return health
