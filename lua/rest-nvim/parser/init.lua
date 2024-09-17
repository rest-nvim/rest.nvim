---@mod rest-nvim.parser rest.nvim http syntax parsing module
---
---@brief [[
---
--- rest.nvim `.http` syntax parsing module.
--- rest.nvim uses `tree-sitter-http` as a core parser for `.http` syntax
---
---@brief ]]

local parser = {}

local Context = require("rest-nvim.context").Context
local utils = require("rest-nvim.utils")
local logger = require("rest-nvim.logger")
local jar = require("rest-nvim.cookie_jar")

---@alias Source integer|string Buffer or string which the `node` is extracted

local NAMED_REQUEST_QUERY = vim.treesitter.query.parse(
    "http",
    [[
(section
  (request_separator
    value: (_) @name)
  request: (_)) @request
(section
  (comment
    name: (_) @_keyword
    value: (_) @name
    (#eq? @_keyword "name"))
  request: (_)) @request
]]
)

---@param node TSNode
---@param field string
---@param source Source
---@return string|nil
local function get_node_field_text(node, field, source)
    local n = node:field(field)[1]
    return n and vim.treesitter.get_node_text(n, source) or nil
end

---@param src string
---@param context rest.Context
---@return string
---@return integer
local function expand_variables(src, context)
    return src:gsub("{{(.-)}}", function(name)
        name = vim.trim(name)
        local res = context:resolve(name)
        return res
    end)
end

---@param req_node TSNode Tree-sitter request node
---@param source Source
---@param context rest.Context
---@return table<string,string[]> headers
local function parse_headers(req_node, source, context)
    local headers = vim.defaulttable(function()
        return {}
    end)
    local header_nodes = req_node:field("header")
    for _, node in ipairs(header_nodes) do
        local key = assert(get_node_field_text(node, "name", source))
        local value = get_node_field_text(node, "value", source)
        key = expand_variables(key, context):lower()
        if value then
            value = expand_variables(value, context)
            table.insert(headers[key], value)
        else
            headers[key] = {}
        end
    end
    return setmetatable(headers, nil)
end

---@param str string
---@return boolean
local function validate_json(str)
    local ok, _ = pcall(vim.json.decode, str)
    return ok
end

---@param str string
---@return boolean
local function validate_xml(str)
    local xml2lua = require("xml2lua")
    local handler = require("xmlhandler.tree"):new()
    local xml_parser = xml2lua.parser(handler)
    local ok = pcall(function(t)
        return xml_parser:parse(t)
    end, str)
    return ok
end

---@param str string
---@return string?
local function parse_urlencoded_form(str)
    local query_pairs = vim.split(str, "&")
    return vim.iter(query_pairs)
        :map(function(query)
            local key, value = query:match("([^=]+)=?(.*)")
            if not key then
                logger.error(("Error while parsing query '%s' from urlencoded form '%s'"):format(query_pairs, str))
                return nil
            end
            return vim.trim(key) .. "=" .. vim.trim(value)
        end)
        :join("&")
end

---@param content_type string?
---@param body_node TSNode
---@param source Source
---@param context rest.Context
---@return rest.Request.Body|nil
function parser.parse_body(content_type, body_node, source, context)
    local body = {}
    local node_type = body_node:type()
    ---@cast body rest.Request.Body
    if node_type == "external_body" then
        body.__TYPE = "external"
        local path = assert(get_node_field_text(body_node, "path", source))
        if type(source) ~= "number" then
            logger.error("can't parse external body on non-existing http file")
            return
        end
        ---@cast source integer
        local basepath = vim.fs.dirname(vim.api.nvim_buf_get_name(source))
        ---@diagnostic disable-next-line: undefined-field
        basepath = basepath:gsub("^" .. vim.pesc(vim.uv.cwd() .. "/"), "")
        path = vim.fs.normalize(vim.fs.joinpath(basepath, path))
        body.data = {
            name = get_node_field_text(body_node, "name", source),
            path = path,
        }
        local body_text = vim.treesitter.get_node_text(body_node, source)
        if vim.startswith(body_text, "<@") then
            logger.debug("external body with '<@' prefix")
            return body
        end
        local file_content = utils.read_file(path)
        file_content = expand_variables(file_content, context)
        body.data.content = file_content
    elseif node_type == "graphql_body" then
        body.__TYPE = "graphql"
        local query_text = vim.treesitter.get_node_text(assert(body_node:named_child(0)), source)
        query_text = expand_variables(query_text, context)
        local variables_text
        local variables_node = body_node:named_child(1)
        if variables_node then
            variables_text = vim.treesitter.get_node_text(variables_node, source)
            variables_text = expand_variables(variables_text, context)
        end
        body.data = vim.json.encode({
            query = query_text,
            variables = vim.json.decode(variables_text),
        })
        logger.debug(body.data)
    elseif node_type == "json_body" or content_type == "application/json" then
        body.__TYPE = "json"
        body.data = vim.trim(vim.treesitter.get_node_text(body_node, source))
        body.data = expand_variables(body.data, context)
        local ok = validate_json(body.data)
        if not ok then
            logger.warn("invalid json: '" .. body.data .. "'")
            return nil
        end
    elseif node_type == "xml_body" or content_type == "application/xml" then
        body.__TYPE = "xml"
        body.data = vim.trim(vim.treesitter.get_node_text(body_node, source))
        body.data = expand_variables(body.data, context)
        local ok = validate_xml(body.data)
        if not ok then
            logger.warn("invalid xml: '" .. body.data .. "'")
            return nil
        end
    elseif node_type == "raw_body" then
        local text = vim.treesitter.get_node_text(body_node, source)
        if content_type and vim.startswith(content_type, "application/x-www-form-urlencoded") then
            body.__TYPE = "raw"
            body.data = parse_urlencoded_form(text)
            if not body.data then
                logger.error("Error while parsing urlencoded form")
                return nil
            end
        else
            body.__TYPE = "raw"
            body.data = text
        end
    elseif node_type == "multipart_form_data" then
        body.__TYPE = "multipart_form_data"
        -- TODO:
        logger.error("multipart form data is not supported yet")
    end
    return body
end

---In-place variables can be evaluated in loaded buffers due to treesitter limitations
---@param source integer
---@param ctx rest.Context
---@param endline number zero-based line number
function parser.eval_context(source, ctx, endline)
    vim.validate({ source = { source, "number" } })
    local startline = ctx.linenr
    for ln = startline, endline do
        local start_node = vim.treesitter.get_node({ pos = { ln, 0 } })
        if start_node then
            local node = utils.ts_find(start_node, "variable_declaration", true)
            if node then
                parser.parse_variable_declaration(node, source, ctx)
            end
        end
    end
end

---@return TSNode? node TSNode with type `section`
function parser.get_request_node_by_cursor()
    local node = vim.treesitter.get_node()
    if node then
        node = utils.ts_find(node, "section")
        if not node then
            logger.error("can't find request section node")
            return
        elseif node:has_error() then
            logger.error(utils.ts_node_error_log(node))
            return
        elseif #node:field("request") < 1 then
            logger.error("request section doesn't have request node")
            return
        end
    end
    return node
end

---@param source Source
---@return TSNode[]
function parser.get_all_request_nodes(source)
    local _, tree = utils.ts_parse_source(source)
    local result = {}
    for node, _ in tree:root():iter_children() do
        if node:type() == "section" and #node:field("request") > 0 then
            table.insert(result, node)
        end
    end
    return result
end

---@return TSNode?
function parser.get_request_node_by_name(name)
    local source = 0
    local _, tree = utils.ts_parse_source(source)
    local query = NAMED_REQUEST_QUERY
    for id, node, _metadata, _match in query:iter_captures(tree:root(), source) do
        local capture_name = query.captures[id]
        if capture_name == "name" and vim.treesitter.get_node_text(node, source) == name then
            local find = utils.ts_find(node, "section")
            if find then
                return find
            end
        end
    end
end

---@param vd_node TSNode
---@param source Source
---@param ctx rest.Context
function parser.parse_variable_declaration(vd_node, source, ctx)
    vim.validate({ node = utils.ts_node_spec(vd_node, "variable_declaration") })
    local name = assert(get_node_field_text(vd_node, "name", source))
    local value = vim.trim(assert(get_node_field_text(vd_node, "value", source)))
    value = expand_variables(value, ctx)
    ctx:set_global(name, value)
end

---@param node TSNode
---@param source Source
---@return string lang
---@return string str
local function parse_script(node, source)
    local lang = "javascript"
    local prev_node = utils.ts_upper_node(node)
    if prev_node and prev_node:type() == "comment" and get_node_field_text(prev_node, "name", source) == "lang" then
        local value = get_node_field_text(prev_node, "value", source)
        if value then
            lang = value
        end
    end
    local script_node = assert(node:named_child(0))
    local str = vim.treesitter.get_node_text(script_node, source):sub(3, -3)
    return lang, str
end

---@param node TSNode
---@param source Source
---@param context rest.Context
function parser.parse_pre_request_script(node, source, context)
    local lang, str = parse_script(node, source)
    local ok, script = pcall(require, "rest-nvim.script." .. lang)
    if not ok then
        logger.error(("failed to load script with language '%s'. Can't find script runner client."):format(lang))
        return
    end
    ---@cast script rest.ScriptClient
    script.load_pre_req_hook(str, context)()
end

---@param node TSNode
---@param source Source
---@param context rest.Context
---@return function?
function parser.parse_request_handler(node, source, context)
    local lang, str = parse_script(node, source)
    local ok, script = pcall(require, "rest-nvim.script." .. lang)
    if not ok then
        logger.error(("failed to load script with language '%s'. Can't find script runner client."):format(lang))
        return
    end
    ---@cast script rest.ScriptClient
    return script.load_post_req_hook(str, context)
end

---@param node TSNode
---@param source Source
---@param ctx rest.Context
---@return function?
function parser.parse_redirect_path(node, source, ctx)
    local force = vim.treesitter.get_node_text(node, source):match("^>>!")
    local path = get_node_field_text(node, "path", source)
    if path then
        path = expand_variables(path, ctx)
        return function(res)
            if not res.body then
                return
            end
            logger.debug("save response body to:", path)
            if not force then
                local suffix_idx = 1
                while utils.file_exists(path) do
                    local pathname, pathext = path:match("([^.]+)(.*)")
                    path = ("%s_%d%s"):format(pathname, suffix_idx, pathext)
                    suffix_idx = suffix_idx + 1
                end
            end
            local respfile, openerr = io.open(path, "w+")
            if not respfile then
                local err_msg = string.format("Failed to open response file (%s): %s", path, openerr)
                vim.notify(err_msg, vim.log.levels.ERROR, { title = "rest.nvim" })
                return
            end
            respfile:write(res.body)
            respfile:close()
            logger.debug("response body saved done")
        end
    end
end

---@param source Source
---@return string[]
function parser.get_request_names(source)
    local _, tree = utils.ts_parse_source(source)
    local query = NAMED_REQUEST_QUERY
    local result = {}
    for id, node, _metadata, _match in query:iter_captures(tree:root(), source) do
        local capture_name = query.captures[id]
        if capture_name == "name" then
            table.insert(result, vim.treesitter.get_node_text(node, source))
        end
    end
    return result
end

---@param name string|nil
---@return TSNode?
function parser.get_request_node(name)
    local req_node
    if not name then
        req_node = parser.get_request_node_by_cursor()
        if not req_node then
            logger.error("Failed to find request at cursor position")
            vim.notify(
                "Failed to find request at cursor position. See `:Rest logs` for more info.",
                vim.log.levels.ERROR,
                { title = "rest.nvim" }
            )
            return
        end
    else
        req_node = parser.get_request_node_by_name(name)
        if not req_node then
            logger.error("Failed to find request by name: " .. name)
            vim.notify(
                "Failed to find request by name: " .. name .. ". See `:Rest logs` for more info.",
                vim.log.levels.ERROR,
                { title = "rest.nvim" }
            )
            return
        end
    end
    return req_node
end

---Parse the request node and create Request object. Returns `nil` if parsing
---failed.
---@param node TSNode Tree-sitter request node
---@param source Source
---@param ctx? rest.Context
---@return rest.Request|nil
function parser.parse(node, source, ctx)
    assert(node:type() == "section")
    assert(not node:has_error())
    local req_node = node:field("request")[1]
    assert(req_node)

    ctx = ctx or Context:new()
    -- TODO: note that in-place variables won't be evaluated for raw string due to treesitter limitations
    -- when source is given as raw string
    if type(source) == "number" then
        local start_row = node:range()
        parser.eval_context(source, ctx, start_row)
    end
    local method = get_node_field_text(req_node, "method", source)
    if not method then
        logger.info("no method provided, falling back to 'GET'")
        method = "GET"
    end
    if method == "GRAPHQL" then
        method = "POST"
    end
    -- NOTE: url will be parsed after because in-place variables should be parsed first
    local url

    ---@type string|nil
    local name
    local handlers = {}
    for child, _ in node:iter_children() do
        local child_type = child:type()
        if child_type == "request" then
            url = expand_variables(assert(get_node_field_text(req_node, "url", source)), ctx)
            url = url:gsub("\n%s+", "")
        elseif child_type == "pre_request_script" then
            parser.parse_pre_request_script(child, source, ctx)
        -- won't be a case anymore with latest tree-sitter-http parser. just for backward compatibility
        elseif child_type == "res_handler_script" then
            local handler = parser.parse_request_handler(child, source, ctx)
            if handler then
                table.insert(handlers, handler)
            end
        elseif child_type == "request_separator" then
            name = get_node_field_text(child, "value", source)
        elseif child_type == "comment" and child:field("name")[1] then
            local comment_name = get_node_field_text(child, "name", source)
            local comment_value = get_node_field_text(child, "value", source)
            if comment_name == "name" then
                name = comment_value or name
            elseif comment_name == "prompt" and comment_value then
                local var_name, var_description = comment_value:match("(%S+)%s*(.*)")
                if var_description == "" then
                    var_description = nil
                end
                vim.ui.input({
                    prompt = (var_description or ("Enter value for `%s`"):format(var_name)) .. ": ",
                    default = ctx:resolve(var_name),
                }, function(input)
                    if input then
                        ctx:set_local(var_name, input)
                    end
                end)
            end
        elseif child_type == "variable_declaration" then
            parser.parse_variable_declaration(child, source, ctx)
        end
    end
    for child, _ in req_node:iter_children() do
        local child_type = child:type()
        if child_type == "res_handler_script" then
            logger.debug("find request node child:", child_type)
            local handler = parser.parse_request_handler(child, source, ctx)
            if handler then
                table.insert(handlers, handler)
            end
        elseif child_type == "res_redirect" then
            logger.debug("find request node child:", child_type)
            local handler = parser.parse_redirect_path(child, source, ctx)
            if handler then
                table.insert(handlers, handler)
            end
        end
    end
    if not name then
        if type(source) == "number" then
            local filename = vim.api.nvim_buf_get_name(source)
            name = filename:match(".*/%.?(.*).http$") or filename
            name = name .. "#" .. vim.b[source]._rest_nvim_count
            vim.b[source]._rest_nvim_count = vim.b[source]._rest_nvim_count + 1
        end
    end

    local headers = parse_headers(req_node, source, ctx)
    if headers["host"] and vim.startswith(url, "/") then
        local host = headers["host"][1]
        if not host:match("^https?://") then
            local port = host:match(":(%d%d+)$")
            local protocol = "http://"
            if not port or port == "443" then
                protocol = "https://"
            end
            host = protocol .. host
        end
        url = host .. url
        table.remove(headers["host"], 1)
    end

    ---@type string?
    local content_type
    if headers["content-type"] and #headers["content-type"] > 0 then
        content_type = headers["content-type"][1]:match("([^;]+)")
    end
    local body
    local body_node = req_node:field("body")[1]
    if body_node then
        body = parser.parse_body(content_type, body_node, source, ctx)
        if not body then
            logger.error("parsing body failed")
            vim.notify(
                "parsing request body failed. See `:Rest logs` for more info.",
                vim.log.levels.ERROR,
                { title = "rest.nvim" }
            )
            return nil
        end
    end

    ---@type rest.Request
    local req = {
        name = name,
        method = method,
        url = url,
        http_version = get_node_field_text(req_node, "version", source),
        headers = headers,
        cookies = {},
        body = body,
        handlers = handlers,
    }
    ctx:clear_local()
    jar.load_cookies(req)
    return req
end

return parser
