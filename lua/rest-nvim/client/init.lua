---@mod rest-nvim.client rest.nvim client module

local clients = {}

---Client to send request
---@class rest.Client
---@field name string name of the client
---Sends request and return the response asynchronously
---@field request fun(req: rest.Request):nio.control.Future
---Check if client can handle given request
---@field available fun(req: rest.Request):boolean

clients.clients = {
    require("rest-nvim.client.curl_cli"),
    -- require("rest-nvim.client.libcurl"),
}

function clients.register_client(client)
    vim.validate({
        client = {
            client,
            function(c)
                return type(c) == "table" and type(c.request) == "function" and type(c.available) == "function"
            end,
            "table with `name`, `request()` and `available()` fields",
        },
    })
    table.insert(clients.clients, client)
end

---Find all registered clients available for given request
---@param req rest.Request
---@return rest.Client[]
function clients.get_available_clients(req)
    return vim.tbl_filter(function(c)
        return c.available(req)
    end, clients.clients)
end

return clients
