<div align="center">

# rest.nvim

![License](https://img.shields.io/github/license/NTBBloodbath/rest.nvim?style=for-the-badge)
![Neovim version](https://img.shields.io/badge/Neovim-0.9.2-5ba246?style=for-the-badge&logo=neovim)
[![LuaRocks](https://img.shields.io/luarocks/v/teto/rest.nvim?style=for-the-badge&logo=lua&color=blue)](https://luarocks.org/modules/teto/rest.nvim)
[![Discord](https://img.shields.io/badge/discord-join-7289da?style=for-the-badge&logo=discord)](https://discord.gg/AcXkuXKj7C)
[![Matrix](https://img.shields.io/matrix/rest.nvim%3Amatrix.org?server_fqdn=matrix.org&style=for-the-badge&logo=element&label=Matrix&color=55b394&link=https%3A%2F%2Fmatrix.to%2F%23%2F%23rest.nvim%3Amatrix.org)](https://matrix.to/#/#rest.nvim:matrix.org)

[Features](#features) • [Install](#install) • [Usage](#usage) • [Contribute](#contribute)

![Demo](https://github.com/rest-nvim/rest.nvim/assets/36456999/e9b536a5-f7b2-4cd8-88fb-fdc5409dd2a4)

</div>

---

A very fast, powerful, extensible and asynchronous Neovim HTTP client written in Lua.

`rest.nvim` by default makes use of native [cURL](https://curl.se/) bindings. In this way, you get
absolutely all the power that cURL provides from the comfort of our editor just by using a keybind
and without wasting the precious resources of your machine.

In addition to this, you can also write integrations with external HTTP clients, such as the postman
CLI. For more information on this, please see this [blog post](https://amartin.codeberg.page/posts/first-look-at-thunder-rest/#third-party-clients).

> [!IMPORTANT]
>
> If you are facing issues, please [report them](https://github.com/rest-nvim/rest.nvim/issues/new) so we can work in a fix together :)

## Features

- Easy to use
- Friendly, organized and featureful request results window
- Fast runtime with statistics about your request
- Set custom pre-request and post-request hooks to dynamically interact with the data
- Easily set environment variables based on the response to re-use the data later
- Tree-sitter based parsing and syntax highlighting for speed and perfect accuracy
- Possibility of using dynamic/environment variables and Lua scripting in HTTP files
- Save received cookies and load them automatically

## Install

> [!NOTE]
>
> rest.nvim requires Neovim >= 0.10.1 to work.

### Dependencies

- System-wide
  - `curl`
- Optional [can be changed, see config below](#default-configuration)
  - `jq`   (to format JSON output)
  - `tidy` (to format HTML output)

### [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim) (recommended)

```vim
:Rocks install rest.nvim
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "rest-nvim/rest.nvim",
}
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "rest-nvim/rest.nvim",
  rocks = { "nvim-nio", "mimetypes", "xml2lua", "fidget.nvim" },
}
```

### Default configuration

This is the default configuration of `rest.nvim`, it is fully documented and typed internally so you
get a good experience during autocompletion :)

> [!NOTE]
>
> You can also check out `:h rest-nvim.config` for documentation.

```lua
---rest.nvim default configuration
---@class rest.Config
local default_config = {
  ---@type table<string, fun():string> Table of custom dynamic variables
  custom_dynamic_variables = {},
  ---@class rest.Config.Request
  request = {
    ---@type boolean Skip SSL verification, useful for unknown certificates
    skip_ssl_verification = false,
    ---Default request hooks
    ---@class rest.Config.Request.Hooks
    hooks = {
      ---@type boolean Encode URL before making request
      encode_url = true,
    },
  },
  ---@class rest.Config.Response
  response = {
    ---@class rest.Config.Response.Hooks
    hooks = {
      ---@type boolean Decode the request URL segments on response UI to improve readability
      decode_url = true,
      ---@type boolean Format the response body
      format = true,
    },
    ---@type table<string,RestResultFormatter>
    formatters = {
      json = "jq",
      html = function(body)
        if vim.fn.executable("tidy") == 0 then
          return body, { found = false, name = "tidy" }
        end
        -- stylua: ignore
        local fmt_body = vim.fn.system({
          "tidy",
          "-i",
          "-q",
          "--tidy-mark",      "no",
          "--show-body-only", "auto",
          "--show-errors",    "0",
          "--show-warnings",  "0",
          "-",
        }, body):gsub("\n$", "")

        return fmt_body, { found = true, name = "tidy" }
      end,
    },
  },
  ---@class rest.Config.Clients
  clients = {
    ---@class rest.Config.Clients.Curl
    curl = {
      ---Statistics to be shown, takes cURL's `--write-out` flag variables
      ---See `man curl` for `--write-out` flag
      ---@type table<string,RestStatisticsStyle>
      statistics = {
        time_total = { winbar = "take", title = "Time taken" },
        size_download = { winbar = "size", title = "Download size" },
      },
    },
  },
  ---@class rest.Config.Cookies
  cookies = {
    ---@type boolean Whether enable cookies support or not
    enable = true,
    ---@type string Cookies file path
    path = vim.fs.joinpath(vim.fn.stdpath("data") --[[@as string]], "rest-nvim.cookies")
  },
  ---@class rest.Config.Env
  env = {
    ---@type boolean
    enable = true,
    ---@type string
    pattern = "%.env.*"
  },
  ---@class rest.Config.UI
  ui = {
    ---@type boolean Whether to set winbar to result panes
    winbar = true,
    ---@class rest.Config.UI.Keybinds
    keybinds = {
      ---@type string Mapping for cycle to previous result pane
      prev = "H",
      ---@type string Mapping for cycle to next result pane
      next = "L",
    },
  },
  ---@class rest.Config.Highlight
  highlight = {
    ---@type boolean Whether current request highlighting is enabled or not
    enable = true,
    ---@type number Duration time of the request highlighting in milliseconds
    timeout = 750,
  },
}
```

### Tree-Sitter parsing

`rest.nvim` uses tree-sitter as a first-class citizen, so it will not work if the required parsers are
not installed. These parsers are as follows and you can add them to your `ensure_installed` table
in your `nvim-treesitter` configuration.

```lua
ensure_installed = { "lua", "xml", "http", "json", "graphql" }
```

Or manually run `:TSInstall lua xml http json graphql`.

## Usage

Create a new http file or open an existing one and place the cursor over the
request and run the <kbd>:Rest run</kbd> command.

> [!NOTE]
>
> 1. You can find examples of use in the [spec/examples](./spec/examples) directory.
>
> 2. `rest.nvim` supports multiple HTTP requests in one file. It selects the
>    request in the current cursor line, no matters the position as long as
>    the cursor is on a request tree-sitter node.

### Keybindings

By default `rest.nvim` does not have any key mappings except the result buffers so you will not have
conflicts with any of your existing ones.

### Commands

| User Command           | Behavior                                             |
|------------------------|------------------------------------------------------|
| `:Rest open`           | Open result pane                                     |
| `:Rest run`            | Run request under the cursor                         |
| `:Rest run {name}`     | Run request with name `{name}`                       |
| `:Rest last`           | Run last request                                     |
| `:Rest logs`           | Edit logs file                                       |
| `:Rest cookies`        | Edit cookies file                                    |
| `:Rest env show`       | Show dotenv file registered to current `.http` file  |
| `:Rest env select`     | Select & register `.env` file with `vim.ui.select()` |
| `:Rest env set {path}` | Register `.env` file to current `.http` file         |

> [!INFO]
> All `:Rest` subcommands opening new window support `command-modifiers` (`:h command-modifiers`.)
> For example, you can run `:hor Rest open` to open result pane in horizontal split.

See `:h rest-nvim.commands` for more info

### Lua scripting

```http
http://localhost:8000

# @lang=lua
> {%
local json = vim.json.decode(response.body)
json.data = "overwritten"
response.body = vim.json.encode(json)
%}
```

Put `# @lang=lua` comment just above any script elements.
Scripts without `@lang` will be parsed as javascript code to match with [http spec](https://www.jetbrains.com/help/idea/exploring-http-syntax.html#response-handling)

## Extensions

### Telescope Extension

`rest.nvim` provides a [telescope.nvim] extension to select the environment variables file,
you can load and use it with the following snippet:

```lua
-- first load extension
require("telescope").load_extension("rest")
-- then use it, you can also use the `:Telescope rest select_env` command
require("telescope").extensions.rest.select_env()
```

Here is a preview of the extension working :)

![telescope rest extension demo](https://github.com/rest-nvim/rest.nvim/assets/36456999/a810954f-b45c-44ee-854d-94039de8e2fc)

#### Mappings

- <kbd>Enter</kbd>: Select Env file
- <kbd>Ctrl + O</kbd>: Edit Env file

#### Config

- `config.env.pattern`: For env file pattern (lua-pattern)

### Lualine Component

We also have lualine component to get what env file you select!

And don't worry, it will only show up under HTTP files.

```lua
-- Just add a component in your lualine config
{
  sections = {
    lualine_x = {
      "rest"
    }
  }
}

-- To use a custom icon and color
{
  sections = {
    lualine_x = {
      {
        "rest",
        icon = "",
        fg = "#428890"
      }
    }
  }
}
```

Here is a preview of the component working :)

![lualine component demo](https://github.com/rest-nvim/rest.nvim/assets/81607010/cf4bb327-61aa-494c-84a5-82f5ee21004f)

## Contribute

1. Fork it (https://github.com/rest-nvim/rest.nvim/fork)
2. Create your feature branch (<kbd>git checkout -b my-new-feature</kbd>)
3. Commit your changes (<kbd>git commit -am 'feat: add some feature'</kbd>)
4. Push to the branch (<kbd>git push -u origin my-new-feature</kbd>)
5. Create a new Pull Request

> [!IMPORTANT]
>
> rest.nvim uses [semantic commits](https://www.conventionalcommits.org/en/v1.0.0/) that adhere to
> semantic versioning and these help with automatic releases, please use this type of convention
> when submitting changes to the project.

Tests can be ran via `make test`. You must have `luarocks` installed to install dependencies. The
test runner through `make test` will automatically install all required dependencies.

## Related software

- [vim-rest-console](https://github.com/diepm/vim-rest-console)
- [Hurl](https://hurl.dev/)
- [HTTPie](https://httpie.io/)
- [httpYac](https://httpyac.github.io/)

## License

rest.nvim is [GPLv3 Licensed](./LICENSE).
