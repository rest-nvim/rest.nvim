<div align="center">

# rest.nvim

![License](https://img.shields.io/github/license/NTBBloodbath/rest.nvim?style=for-the-badge)
![Neovim version](https://img.shields.io/badge/Neovim-0.5-57A143?style=for-the-badge&logo=neovim)

[Features](#features) • [Install](#install) • [Usage](#usage) • [Contribute](#contribute)

![Demo](./assets/demo.png)

</div>

---

A fast Neovim http client written in Lua.

`rest.nvim` makes use of a curl wrapper made in pure Lua by [tami5] and implemented
in `plenary.nvim` so, in other words, `rest.nvim` is a curl wrapper so you don't
have to leave Neovim!

> **IMPORTANT:** If you are facing issues, please [report them](https://github.com/rest-nvim/rest.nvim/issues/new)

## Notices

- **2023-07-12**: tagged 0.2 release before changes for 0.10 compatibility
- **2021-11-04**: HTTP Tree-Sitter parser now depends on JSON parser for the JSON bodies detection,
  please install it too.
- **2021-08-26**: We have deleted the syntax file for HTTP files to start using the tree-sitter parser instead,
  please see [Tree-Sitter parser](#tree-sitter-parser) section for more information.
- **2021-07-01**: Now for getting syntax highlighting in http files you should
  add a `require('rest-nvim').setup()` to your `rest.nvim` setup, refer to [packer.nvim](#packernvim).
  This breaking change should allow lazy-loading of `rest.nvim`.

## Features

- Easy to use
- Fast execution time
- Run request under cursor
- Syntax highlight for http files and output
- Possibility of using environment variables in http files

## Install

> **WARNING:** rest.nvim requires Neovim >= 0.5 to work.

### Dependencies

- System-wide
  - curl
- Optional [can be changed, see config below]
  - jq   (to format JSON output)
  - tidy (to format HTML output)
- Other plugins
  - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

### packer.nvim

```lua
use {
  "rest-nvim/rest.nvim",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    require("rest-nvim").setup({
      -- Open request results in a horizontal split
      result_split_horizontal = false,
      -- Keep the http file buffer above|left when split horizontal|vertical
      result_split_in_place = false,
      -- Skip SSL verification, useful for unknown certificates
      skip_ssl_verification = false,
      -- Encode URL before making request
      encode_url = true,
      -- Highlight request on run
      highlight = {
        enabled = true,
        timeout = 150,
      },
      result = {
        -- toggle showing URL, HTTP info, headers at top the of result window
        show_url = true,
        -- show the generated curl command in case you want to launch
        -- the same request via the terminal (can be verbose)
        show_curl_command = false,
        show_http_info = true,
        show_headers = true,
        -- table of curl `--write-out` variables or false if disabled
        -- for more granular control see Statistics Spec
        show_statistics = false,
        -- executables or functions for formatting response body [optional]
        -- set them to false if you want to disable them
        formatters = {
          json = "jq",
          html = function(body)
            return vim.fn.system({"tidy", "-i", "-q", "-"}, body)
          end
        },
      },
      -- Jump to request line on run
      jump_to_request = false,
      env_file = '.env',
      custom_dynamic_variables = {},
      yank_dry_run = true,
    })
  end
}
```

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
-- plugins/rest.lua
return {
   "rest-nvim/rest.nvim",
   dependencies = { { "nvim-lua/plenary.nvim" } },
   config = function()
     require("rest-nvim").setup({
       --- Get the same options from Packer setup
    })
  end
}
```

### Tree-Sitter parser

We are using a Tree-Sitter parser for our HTTP files, in order to get the correct syntax highlighting
for HTTP files (including JSON bodies) you should add the following into your `ensure_installed` table
in your tree-sitter setup.

```lua
ensure_installed = { "http", "json" }
```

Or manually run `:TSInstall http json`.

## Keybindings

By default `rest.nvim` does not have any key mappings so you will not have
conflicts with any of your existing ones.

To run `rest.nvim` you should map the following commands:
- `<Plug>RestNvim`, run the request under the cursor
- `<Plug>RestNvimPreview`, preview the request cURL command
- `<Plug>RestNvimLast`, re-run the last request

## Settings

- `result_split_horizontal` opens result on a horizontal split (default opens
    on vertical)
- `result_split_in_place` opens result below|right on horizontal|vertical split
    (default opens top|left on horizontal|vertical split)
- `skip_ssl_verification` passes the `-k` flag to cURL in order to skip SSL verification,
    useful when using unknown certificates
- `encode_url` flag to encode the URL before making request
- `highlight` allows to enable and configure the highlighting of the selected request when send,
- `jump_to_request` moves the cursor to the selected request line when send,
- `env_file` specifies file name that consist environment variables (default: .env)
- `custom_dynamic_variables` allows to extend or overwrite built-in dynamic variable functions
    (default: {})

### Statistics Spec

| Property | Type               | Description                                            |
| :------- | :----------------- | :----------------------------------------------------- |
| [1]      | string             | `--write-out` variable name, see `man curl`. Required. |
| title    | string             | Replaces the variable name in the output if defined.   |
| type     | string or function | Specifies type transformation for the output value. Default transformers are `time` and `byte`. Can also be a function which takes the value as a parameter and returns a string. |

## Usage

Create a new http file or open an existing one and place the cursor over the
request method (e.g. `GET`) and run `rest.nvim`.

> **NOTES**:
>
> 1. `rest.nvim` follows the RFC 2616 request format so any other
>    http file should work without problems.
>
> 2. You can find examples of use in [tests](./tests)

---

### Debug


Run `export DEBUG_PLENARY="debug"` before starting nvim. Logs will appear most
likely in ~/.cache/nvim/rest.nvim.log


## Contribute

1. Fork it (https://github.com/rest-nvim/rest.nvim/fork)
2. Create your feature branch (<kbd>git checkout -b my-new-feature</kbd>)
3. Commit your changes (<kbd>git commit -am 'Add some feature'</kbd>)
4. Push to the branch (<kbd>git push origin my-new-feature</kbd>)
5. Create a new Pull Request

To run the tests, enter a nix shell with `nix develop ./contrib`, then run `make
test`.

## Related software

- [vim-rest-console](https://github.com/diepm/vim-rest-console)
- [Hurl](https://hurl.dev/)
- [HTTPie](https://httpie.io/)
- [httpYac](https://httpyac.github.io/)

## License

rest.nvim is [MIT Licensed](./LICENSE).

[tami5]: https://github.com/tami5
