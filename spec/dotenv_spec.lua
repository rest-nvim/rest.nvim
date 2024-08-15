---@module 'luassert'

require("spec.minimum_init")

local function open(path)
  vim.cmd.edit(path)
  vim.cmd.source("ftplugin/http.lua")
  return 0
end

local function remove_cwd(path)
  path = path:gsub(vim.pesc(vim.fn.getcwd()) .. "/", "")
  return path
end

describe("dotenv", function ()
  it("find dotenv file with same name to http file", function ()
    open("spec/examples/dotenv/with_dotenv.http")
    assert.same(
      "spec/examples/dotenv/with_dotenv.env",
      remove_cwd(vim.b._rest_nvim_env_file)
    )
  end)
  it("find dotenv file in parent dir", function ()
    open("spec/examples/dotenv/without_dotenv.http")
    assert.same(
      "spec/examples/.env",
      remove_cwd(vim.b._rest_nvim_env_file)
    )
  end)
end)
