local script = {}
local logger = require("rest-nvim.logger")

local has_js = vim.fn.executable('node')

if has_js == 0 then
    print("node is not available")
end

local function cwd()
  local current_script_path = debug.getinfo(1).source:match("@(.*)")
  return current_script_path:match("(.*[/\\])") or "."
end

local function read_file(filename)
    local file_to_open = cwd() .. "/" .. filename

    local file = io.open(file_to_open, "r")
    if file then
      local file_content = file:read("*all")
      file:close()
      return file_content
    else
      print("Error: Could not open file " .. file_to_open)
    end
end

local function write_file(filename, content)
    local file_to_open = cwd() .. "/" .. filename
    local file = io.open(file_to_open, "w")
    if file then
      file:write(content)
      file:close()
    else
      print("Error: Could not open file " .. file_to_open)
    end
    return file_to_open
end

local function local_vars (ctx)
    local ctx_vars = {}
    for k, v in pairs(ctx.vars) do
        ctx_vars[k] = v
    end
    for k, v in pairs(ctx.lv) do
        ctx_vars[k] = v
    end
    return ctx_vars
end

local function create_prescript_env(ctx)
    return {
        _env = { cwd = cwd() },
        request = { variables = local_vars(ctx) }
    }
end

local function create_handler_env(ctx, res)
    local response = res
    -- TODO check mime type before parsing
    local ok, decoded_body = pcall(vim.fn.json_decode, res.body)
    if ok then
      response = vim.deepcopy(res)
      response.body = decoded_body
    end

    return {
        _env = { cwd = cwd() },
        client = { global = { data = {} } },
        request = { variables = local_vars(ctx) },
        response = response,
    }
end

local function execute_cmd(cmd)
    local handle = io.popen(cmd)
    if handle then
        local result = handle:read("*a")
        handle:close()
        return result
    end
end

local js_str = read_file("javascript.mjs");

local function load_js(s, env)
    local env_json = vim.fn.json_encode(env):gsub("\\", "\\\\")  -- Escape backslashes

    -- uncomment to load each time when developing
    -- local js_str = read_file("javascript.mjs");

    local js_code = string.format(js_str, env_json, s)

    -- save to file so no need to escape quotes
    local file_path = write_file('last_javascript.mjs', js_code)

    local ok, result = pcall(function()
        return execute_cmd("node " .. file_path)
    end)
    if not ok then
        logger.error("JS execution error: " .. tostring(result))
        return nil
    end

    return result
end

local function split_string_on_separator(multiline_str)
    local before_separator = {}
    local after_separator = {}
    local found_separator = false

    for line in multiline_str:gmatch("[^\r\n]+") do
        if line == "-ENV-" then
            found_separator = true
        elseif found_separator then
            table.insert(after_separator, line)
        else
            table.insert(before_separator, line)
        end
    end

    return table.concat(before_separator), table.concat(after_separator)
end

local function update_local(ctx, env_json)
  for key, value in pairs(env_json.request.variables) do
     ctx:set_local(key, value)
  end
end

local function update_global(env, env_json)
  for key, value in pairs(env_json.client.global.data) do
     env[key] = value
  end
end

function script.load_pre_req_hook(s, ctx)
    return function ()
        local result = load_js(s, create_prescript_env(ctx))
        local logs, json_str = split_string_on_separator(result)
        print(logs)
        local env_json = vim.fn.json_decode(json_str)
        update_local(ctx, env_json)
    end
end

function script.load_post_req_hook(s, ctx)
    return function(res)
        local result = load_js(s, create_handler_env(ctx, res))
        local logs, json_str = split_string_on_separator(result)
        print(logs)
        local env_json = vim.fn.json_decode(json_str)
        update_global(vim.env, env_json)
        update_local(ctx, env_json)
    end
end

return script
