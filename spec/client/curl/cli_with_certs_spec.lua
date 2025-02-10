---@diagnostic disable: invisible
---@module 'luassert'

require("spec.minimal_init")
vim.g.rest_nvim = vim.tbl_deep_extend("force", {
    clients = {
        curl = {
            opts = {
                certificates = {
                    ["localhost"] = {
                        set_certificate_crt = "./my.cert",
                        set_certificate_key = "./my.key",
                    },
                },
            },
        },
    },
}, vim.g.rest_nvim)

local Context = require("rest-nvim.context").Context
local curl = require("rest-nvim.client.curl.cli")
local builder = curl.builder

local STAT_FORMAT = builder.STAT_ARGS[2]

require("rest-nvim.client.curl.cli").config = vim.g.rest_nvim

describe("Curl cli builder", function()
    it("with opts.certificates", function()
        local args = builder.build({
            context = Context.new(),
            method = "POST",
            url = "http://localhost:8000",
            headers = {},
            cookies = {},
            handlers = {},
        })
        assert.same({
            "http://localhost:8000",
            "--cert",
            "./my.cert",
            "--key",
            "./my.key",
            "-X",
            "POST",
            "-w",
            STAT_FORMAT,
        }, args)
    end)
end)
