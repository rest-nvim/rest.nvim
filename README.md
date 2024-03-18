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
- Friendly and organized request results window
- Fast runtime with statistics about your request
- Set custom pre-request and post-request hooks to dynamically interact with the data
- Easily set environment variables based on the response to re-use the data later
- Tree-sitter based parsing and syntax highlighting for speed and perfect accuracy
- Possibility of using dynamic/environment variables and Lua scripting in HTTP files

## Install

> [!NOTE]
>
> rest.nvim requires Neovim >= 0.9.2 to work.

### Dependencies

- System-wide
  - `Python` (only if you are using `packer.nvim` or `lazy.nvim` plus `luarocks.nvim` for the installation)
  - `cURL` development headers (usually called `libcurl-dev` or `libcurl-devel` depending on your Linux distribution)
- Optional [can be changed, see config below](#default-configuration)
  - `jq`   (to format JSON output)
  - `tidy` (to format HTML output)

> [!NOTE]
>
> 1. Python will be unnecessary once `luarocks.nvim` gets rid of it as a dependency in the `go-away-python` branch.
>
> 2. I will be working on making a binary rock of `Lua-cURL` so that the `cURL` development headers are not
> necessary for the installation process.

### [rocks.nvim](https://github.com/nvim-neorocks/rocks.nvim) (recommended)

```vim
:Rocks install rest.nvim
```

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "rest-nvim/rest.nvim",
  rocks = { "lua-curl", "nvim-nio", "mimetypes", "xml2lua" },
  config = function()
    require("rest-nvim").setup()
  end,
}
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "vhyrro/luarocks.nvim",
  config = function()
    require("luarocks").setup({})
  end,
},
{
  "rest-nvim/rest.nvim",
  ft = "http",
  dependencies = { "luarocks.nvim" },
  config = function()
    require("rest-nvim").setup()
  end,
}
```

> [!NOTE]
>
> There's a `build.lua` file in the repository that `lazy.nvim` will find and source to install the
> luarocks dependencies for you by using `luarocks.nvim`.

### Default configuration

This is the default configuration of `rest.nvim`, it is fully documented and typed internally so you
get a good experience during autocompletion :)

> [!NOTE]
>
> You can also check out `:h rest-nvim.config` for documentation.

```lua
local default_config = {
  client = "curl",
  env_file = ".env",
  env_pattern = "\\.env$",
  env_edit_command = "tabedit",
  encode_url = true,
  skip_ssl_verification = false,
  custom_dynamic_variables = {},
  logs = {
    level = "info",
    save = true,
  },
  result = {
    split = {
      horizontal = false,
      in_place = false,
      stay_in_current_window_after_split = true,
    },
    behavior = {
      decode_url = true,
      show_info = {
        url = true,
        headers = true,
        http_info = true,
        curl_command = true,
      },
      statistics = {
        enable = true,
        ---@see https://curl.se/libcurl/c/curl_easy_getinfo.html
        stats = {
          { "total_time", title = "Time taken:" },
          { "size_download_t", title = "Download size:" },
        },
      },
      formatters = {
        json = "jq",
        html = function(body)
          if vim.fn.executable("tidy") == 0 then
            return body, { found = false, name = "tidy" }
          end
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
  },
  highlight = {
    enable = true,
    timeout = 750,
  },
  ---Example:
  ---
  ---```lua
  ---keybinds = {
  ---  {
  ---    "<localleader>rr", "<cmd>Rest run<cr>", "Run request under the cursor",
  ---  },
  ---  {
  ---    "<localleader>rl", "<cmd>Rest run last<cr>", "Re-run latest request",
  ---  },
  ---}
  ---
  ---```
  ---@see vim.keymap.set
  keybinds = {},
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

## Keybindings

By default `rest.nvim` does not have any key mappings so you will not have
conflicts with any of your existing ones.

However, `rest.nvim` exposes a `:Rest` command in HTTP files that you can use to create your
keybinds easily. For example:

```lua
keybinds = {
  {
    "<localleader>rr", "<cmd>Rest run<cr>", "Run request under the cursor",
  },
  {
    "<localleader>rl", "<cmd>Rest run last<cr>", "Re-run latest request",
  },
}
```

You can still also use the legacy `<Plug>RestNvim` commands for mappings:
- `<Plug>RestNvim`, run the request under the cursor
- `<Plug>RestNvimLast`, re-run the last request

> [!NOTE]
>
> 1. `<Plug>RestNvimPreview` has been removed, as we can no longer implement it with the current
>    cURL implementation.
>
> 2. The legacy `<Plug>` mappings will raise a deprecation warning suggesting you to switch to
>    the `:Rest` command, as they are going to be completely removed in the next version.

## Usage

Create a new http file or open an existing one and place the cursor over the
request and run the <kbd>:Rest run</kbd> command.

> [!NOTE]
>
> 1. You can find examples of use in the [tests](./tests) directory.
>
> 2. `rest.nvim` supports multiple HTTP requests in one file. It selects the
>    request in the current cursor line, no matters the position as long as
>    the cursor is on a request tree-sitter node.


---

### Telescope Extension

`rest.nvim` provides a [telescope.nvim] extension to select the environment variables file,
you can load and use it with the following snippet:

```lua
-- first load extension
require("telescope").load_extension("rest")
-- then use it, you can also use the `:Telescope rest select_env` command
require("telescope").extensions.rest.select_env()
```

If running Ubuntu or Debian based systems you might need to run `ln -s $(which fdfind) ~/.local/bin/fd` to get extension to work. This is becuase extension runs the [fd](https://github.com/sharkdp/fd?tab=readme-ov-file#installation) command.

Here is a preview of the extension working :)

![telescope rest extension demo](https://github.com/rest-nvim/rest.nvim/assets/36456999/a810954f-b45c-44ee-854d-94039de8e2fc)

### Mappings

- <kbd>Enter</kbd>: Select Env file
- <kbd>Ctrl + O</kbd>: Edit Env file

### Config

- `env_pattern`: For env file pattern
- `env_edit_command`: For env file edit command

## Lualine

We also have lualine component to get what env file you select!

And dont't worry, it will only show up under HTTP files.

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

## Related software

- [vim-rest-console](https://github.com/diepm/vim-rest-console)
- [Hurl](https://hurl.dev/)
- [HTTPie](https://httpie.io/)
- [httpYac](https://httpyac.github.io/)

## License

rest.nvim is [GPLv3 Licensed](./LICENSE).
