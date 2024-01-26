---@mod rest-nvim.commands rest.nvim commands
---
---@brief [[
---
--- `:Rest {command {args?}}`
---
--- command                         action
---------------------------------------------------------------------------------
---
--- run {scope?}                    Execute one or several HTTP requests depending
---                                 on given `scope`. This scope can be either `last`,
---                                 `cursor` (default) or `document`.
--- last                            Re-run the last executed request, alias to `run last`
---                                 to retain backwards compatibility with the old keybinds
---                                 layout.
--- preview                         Preview the cURL command that is going to be ran while
---                                 executing the request (this does NOT run the request).
---
---@brief ]]

---@class RestCmd
---@field impl fun(args:string[], opts: vim.api.keyset.user_command) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's argument

local commands = {}

local functions = require("rest-nvim.functions")

---@type { [string]: RestCmd }
local rest_command_tbl = {
  run = {
    impl = function(args)
      local request_scope = #args == 0 and "cursor" or args[1]
      functions.exec(request_scope, false)
    end,
    ---@return string[]
    complete = function(args)
      local scopes = { "last", "cursor", "document" }
      if #args < 1 then
        return scopes
      end

      local match = vim.tbl_filter(function(scope)
        if string.find(scope, "^" .. args) then
          return scope
        ---@diagnostic disable-next-line missing-return
        end
      end, scopes)

      return match
    end,
  },
  last = {
    impl = function(_)
      functions.exec("last", false)
    end,
  },
  preview = {
    impl = function(_)
      functions.exec("cursor", true)
    end
  },
  env = {
    impl = function(args)
      vim.print(args)
      -- If there were no arguments for env then default to the `env("show", nil)` function behavior
      if #args < 1 then
        functions.env(nil, nil)
        return
      end
      -- If there was only one argument and it is `set` then raise an error because we are also expecting for the env file path
      if #args == 1 and args[1] == "set" then
        vim.notify(
          "Rest: Not enough arguments were passed to the 'env' command: 2 argument were expected, 1 was passed",
          vim.log.levels.ERROR
        )
        return
      end
      -- We do not need too many arguments here, complain about it please!
      if #args > 3 then
        vim.notify(
          "Rest: Too many arguments were passed to the 'env' command: 2 arguments were expected, " .. #args .. " were passed"
        )
        return
      end

      functions.env(args[1], args[2])
    end,
    ---@return string[]
    complete = function(args)
      local actions = { "set", "show" }
      if #args < 1 then
        return actions
      end

      -- If the completion arguments have a whitespace then treat them as a table instead for easiness
      if args:find(" ") then
        args = vim.split(args, " ")
      end
      -- If the completion arguments is a table and `set` is the desired action then
      -- return a list of files in the current working directory for completion
      if type(args) == "table" and args[1]:match("set") then
        -- We are currently looking for any ".*env*" file, e.g. ".env", ".env.json"
        --
        -- This algorithm can be improved later on to search from a parent directory if the desired environment file
        -- is somewhere else but in the current working directory.
        local files = vim.fs.find(function(name, path)
          return name:match(".*env.*$")
        end, { limit = math.huge, type = "file", path = "./" })

        return files
      end

      local match = vim.tbl_filter(function(action)
        if string.find(action, "^" .. args) then
          return action
        ---@diagnostic disable-next-line missing-return
        end
      end, actions)

      return match
    end,
  }
}

local function rest(opts)
  local fargs = opts.fargs
  local cmd = fargs[1]
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local command = rest_command_tbl[cmd]
  if not command then
    vim.notify("Rest: Unknown command: " .. cmd, vim.log.levels.ERROR)
    return
  end

  command.impl(args)
end

---@package
function commands.init(bufnr)
  vim.api.nvim_buf_create_user_command(bufnr, "Rest", rest, {
    nargs = "+",
    desc = "Run or preview your HTTP requests",
    complete = function(arg_lead, cmdline, _)
      local rest_commands = vim.tbl_keys(rest_command_tbl)
      local subcmd, subcmd_arg_lead = cmdline:match("^Rest*%s(%S+)%s(.*)$")
      if subcmd and subcmd_arg_lead and rest_command_tbl[subcmd] and rest_command_tbl[subcmd].complete then
        return rest_command_tbl[subcmd].complete(subcmd_arg_lead)
      end
      if cmdline:match("^Rest*%s+%w*$") then
        return vim.tbl_filter(function(cmd)
          if string.find(cmd, "^" .. arg_lead) then
            return cmd
          ---@diagnostic disable-next-line missing-return
          end
        end, rest_commands)
      end
    end,
  })
end

---Register a new `:Rest` subcommand
---@see vim.api.nvim_buf_create_user_command
---@param name string The name of the subcommand
---@param cmd RestCmd The implementation and optional completions
---@package
function commands.register_subcommand(name, cmd)
  vim.validate({ name = { name, "string" } })
  vim.validate({ impl = { cmd.impl, "function" }, complete = { cmd.complete, "function", true } })

  rest_command_tbl[name] = cmd
end

return commands
