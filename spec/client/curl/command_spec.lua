---@module 'luassert'

require("spec.minimal_init")

local nio = require("nio")
local spy = require("luassert.spy")

local function open(path)
    vim.cmd.edit(path)
    return 0
end

---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function() end

describe(":Rest curl", function()
    assert(vim.g.loaded_rest_nvim)
    it("yank cursor position", function()
        open("spec/examples/basic_get.http")
        vim.cmd("Rest curl yank")
        assert.same(
            "curl -sL 'https://api.github.com/users/boltlessengineer' '-X' 'GET' '-H' 'User-Agent: neovim'\n",
            vim.fn.getreg("+")
        )
    end)
end)

describe(":Rest run", function()
    nio.tests.it("notify on request failed", function()
        open("spec/examples/basic_get.http")
        -- go to line number 6
        vim.cmd("6")
        local spy_notify = spy.on(vim, "notify")
        -- run request
        vim.cmd(":Rest run")
        nio.sleep(100)
        assert
            ---@diagnostic disable-next-line: undefined-field
            .spy(spy_notify)
            .called_with("request failed. See `:Rest logs` for more info", vim.log.levels.ERROR, { title = "rest.nvim" })
    end)
end)
