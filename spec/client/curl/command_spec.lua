---@module 'luassert'

require("spec.minimum_init")

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
            "curl -sL 'https://api.github.com/users/boltlessengineer' '-X' 'GET' '-H' 'User-Agent: neovim'",
            vim.fn.getreg("+")
        )
    end)
end)
