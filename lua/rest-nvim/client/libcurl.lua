local libcurl = require("rest-nvim.client.curl.libcurl")

local nio = require("nio")

local COMPATIBLE_METHODS = {
    "OPTIONS",
    "GET",
    "HEAD",
    "POST",
    "PUT",
    "DELETE",
    "TRACE",
    "CONNECT",
    "PATCH",
    "LIST",
}

local COMPATIBLE_BODY_TYPES = {
    "json",
    "xml",
    "external",
    "form",
}

---@type rest.Client
local client = {
    name = "libcurl",
    request = function(req)
        local res = libcurl.request(req)
        local future = nio.control.future()
        future.set(res)
        return future
    end,
    available = function(req)
        local method_ok = vim.list_contains(COMPATIBLE_METHODS, req.method)
        local url_ok = req.url:match("^https?://")
        local body_ok = (not req.body) or vim.list_contains(COMPATIBLE_BODY_TYPES, req.body.__TYPE)
        return method_ok and url_ok and body_ok
    end,
}

return client
