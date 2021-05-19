<div align="center">

# rest.nvim

![License](https://img.shields.io/github/license/NTBBloodbath/doom-nvim?style=flat-square)
![Neovim version](https://img.shields.io/badge/Neovim-0.5-57A143?style=flat-square&logo=neovim)

[Features](#features) • [Install](#install) • [Usage](#usage) • [Contribute](#contribute)

![Demo](./assets/demo.png)

</div>

---

A fast Neovim http client written in Lua.

`rest.nvim` makes use of a curl wrapper made in pure Lua by [tami5] and implemented
in `plenary.nvim` so, in other words, `rest.nvim` is a curl wrapper so you don't
have to leave Neovim!

> **IMPORTANT:** If you are facing issues, please [report them](https://github.com/NTBBloodbath/rest.nvim/issues/new)

# Features

- Easy to use
- Fast execution time
- Run request under cursor
- Syntax highlight for http files and output
- Possibility of using environment variables in http files

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

To run `rest.nvim` you should map the `<Plug>RestNvim` command.

# Usage

Create a new http file or open an existing one and place the cursor over the
request method (e.g. `GET`) and run `rest.nvim`.

> **NOTES**:
>
> 1. `rest.nvim` follows the RFC 2616 request format so any other
>    http file should work without problems.
>
> 2. You can find examples of use in [tests](./tests)

---

# Contribute

1. Fork it (https://github.com/NTBBloodbath/rest.nvim/fork)
2. Create your feature branch (<kbd>git checkout -b my-new-feature</kbd>)
3. Commit your changes (<kbd>git commit -am 'Add some feature'</kbd>)
4. Push to the branch (<kbd>git push origin my-new-feature</kbd>)
5. Create a new Pull Request

# License

rest.nvim is [MIT Licensed](./LICENSE).

[tami5]: https://github.com/tami5
