<div align="center">

# rest.nvim

![License](https://img.shields.io/github/license/NTBBloodbath/doom-nvim?style=flat-square)
![Neovim version](https://img.shields.io/badge/Neovim-0.5-57A143?style=flat-square&logo=neovim)

[Features](#features) • [Install](#install) • [Contribute](#contribute)

![Demo](./assets/demo.png)

</div>

---

A fast Neovim http client written in Lua in less than 250 lines.

> **IMPORTANT:** `rest.nvim` is a WIP, there may be things that doesn't work properly _yet_.
>
> If you are facing issues, please [report them](https://github.com/NTBBloodbath/rest.nvim/issues/new)

# Features

- Easy to use
- JSON body support
- Fast execution time
- Run request under cursor
- Syntax highlight for http files and output

# Install

> **WARNING:** rest.nvim requires Neovim >= 0.5 to work.

### Dependencies

- System-wide
  - curl
  - jq (to format JSON output so it can be human-readable)
- Other plugins
  - [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## packer.nvim

```lua
use {
    'NTBBloodbath/rest.nvim',
    requires = { 'nvim-lua/plenary.nvim' }
}
```

# Keybindings

By default `rest.nvim` does not have any key mappings so you will not have
conflicts with any of your existing ones.

To run `rest.nvim`, you should use `:lua require('rest-nvim').run()<CR>`

# Usage

Create a new http file or open an existing one and place the cursor over the
request method (e.g. `GET`) and run `rest.nvim`.

```http
GET http://localhost:3000/foo
```

If you want to use headers, then put a `HEADERS` block below the request statement.

```http
POST http://localhost:3000/foo

HEADERS {
    "foo": "bar"
}

BODY {
    "json": "body"
}
```

---

# Contribute

1. Fork it (https://github.com/NTBBloodbath/rest.nvim/fork)
2. Create your feature branch (<kbd>git checkout -b my-new-feature</kbd>)
3. Commit your changes (<kbd>git commit -am 'Add some feature'</kbd>)
4. Push to the branch (<kbd>git push origin my-new-feature</kbd>)
5. Create a new Pull Request

> **NOTE:** Before commit your changes, format the code by running `make fmt`.

# License

nvenv is [MIT Licensed](./LICENSE).
