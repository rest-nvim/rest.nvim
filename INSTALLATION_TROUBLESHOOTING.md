# Check if plugin manager supports rockspec

`rest.nvim` has several dependencies specified in rockspec.
You need a plugin manager supporting rockspec such as [`lazy.nvim`] and [`rocks.nvim`]
to properly install this plugin.

## Using `lazy.nvim`

> [^IMPORTANT]
> As this plugin already specified all required dependencies in rockspec, you don't
> need to specify any dependencies as you usually do in lazyspec.

`lazy.nvim` requires `luarocks` as a system dependency to support rockspec.[^1][^2]

You can check if the installed `lazy.nvim` is properly set for rockspec through the
following command.

```vim
:checkhealth lazy
```

In *luarocks* section, you should see something like this:

```
...

luarocks ~
- checking `hererocks` installation
- you have some plugins that require `luarocks`:
    * `hererocks`
    * `rest.nvim`
- OK {python3} `Python 3.10.12`
- OK {/home/ubuntu/.local/share/nvim/lazy-rocks/hererocks/bin/luarocks} `3.11.1`
- OK {/home/ubuntu/.local/share/nvim/lazy-rocks/hererocks/bin/lua} `Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio`

```

## Using `rocks.nvim` (recommended)

`rocks.nvim` requires `lua5.1` or `luajit` as a system dependency to work.[^3]

You can check if the installed `rocks.nvim` is properly set for rockspec through the
following command.

```vim
:checkhealth rocks
```

You should see something like this:

```

==============================================================================
rocks: require("rocks.health").check()

Checking external dependencies ~
- OK luarocks: found
- OK lua: found Lua 5.1.5  Copyright (C) 1994-2012 Lua.org, PUC-Rio

Checking rocks.nvim config ~
- OK No errors found in config.

Checking rocks.toml ~
- OK No errors found in rocks.toml.

Checking tree-sitter parsers ~
- OK No tree-sitter issues detected.

```

# Issue troubleshooting

## Dependency `...` was not found

This happens when your plugin manager didn't install the required dependencies specified in
rockspec.
Both `rocks.nvim` and *latest version of* `lazy.nvim` supports rockspec installation.
If you are seeing this issue, you may be using old version of `lazy.nvim`.

## `lua5.1` or `lua` or `lua-5.1` version `5.1` not installed

By default, `lazy.nvim` will automatically install required versions of `lua` and `luarocks`
*if `luarocks` doesn't exist in your machine*.
But if `luarocks` exists, `lazy.nvim` won't do anything even if installed version is not compatible.

By setting `opts.rocks.hererocks = true` in your `lazy.nvim` config, you can force `lazy.nvim` to
always install the correct versions of `lua` and `luarocks` for Neovim.

**Example:**
```lua
require("lazy").setup({
    spec = {
        -- ...
        "rest-nvim/rest.nvim",
    },
    rocks = {
        hererocks = true, -- you should enable this to get hererocks support
    },
    -- ...
})
```

`hererocks` option is completely optional but highly recommended if you don't want to deal with
system package versions.

## Can't install on Windows

See [this issue](https://github.com/rest-nvim/rest.nvim/issues/463) for Windows installation.

---

Please [open a new issue](https://github.com/rest-nvim/rest.nvim/issues/new/choose) if you still
have any issue after trying this guide.

[^1]: https://lazy.folke.io/#%EF%B8%8F-requirements
[^2]: You also need `lua5.1` in your system to properly setup `luarocks`
[^3]: https://github.com/nvim-neorocks/rocks.nvim?tab=readme-ov-file#pencil-requirements

[`lazy.nvim`]: https://github.com/folke/lazy.nvim
[`hererocks`]: https://github.com/mpeterv/hererocks
[`rocks.nvim`]: https://github.com/nvim-neorocks/rocks.nvim
