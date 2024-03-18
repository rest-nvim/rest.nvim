local M = {}

---@alias PluginName string The plugin name, will be used as part of the git clone destination
---@alias PluginUrl string The git url at which a plugin is located, can be a path. See https://git-scm.com/book/en/v2/Git-on-the-Server-The-Protocols for details
---@alias GitPlugins table<PluginName, PluginUrl> Plugins to clone with git

-- Gets the current directory of this file
local test_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local rest_nvim_dir = vim.fn.fnamemodify(test_dir, ":h")

---Gets the root directory of the minimal init and if path is specified appends the given path to the root allowing for
---subdirectories within the current cwd
---@param path string? The additional path to append to the root, not required
---@return string root The root path suffixed with the path provided or an empty suffix if none was given
function M.root(path)
  return test_dir .. "/.deps/" .. (path or "")
end

---Returns the package root and ensures the path exists on disk
---@return string pkg_root The package root suffixed with a `/`
M.package_root = function()
  local pkg_root = M.root("plugins/")
  if not vim.uv.fs_stat(pkg_root) then
    vim.fn.mkdir(pkg_root, "p")
  end
  return pkg_root
end

---Run a system command through `vim.system` and error on failed commands
---@param cmd string[] The command to run
---@param opts vim.SystemOpts? Options to pass to `vim.system`
---@return vim.SystemCompleted
function M.system(cmd, opts)
  local out = vim.system(cmd, opts or {}):wait()
  if out.code ~= 0 then
    error(
      string.format(
        ">> Failed to run command: "
          .. table.concat(cmd, " ")
          .. "\n>> Exit code: %d\n>> Signal: %d\n===== STDOUT =====\n%s\n===== STDERR =====\n%s\n",
        out.code,
        out.signal,
        out.stdout,
        out.stderr
      ),
      vim.log.levels.ERROR
    )
  end
  return out
end

---Make the `rest.nvim` lua rock and register the resulting plugin on the `runtimepath`
function M.make_luarock()
  print(">> Making rest.nvim luarock")
  local luarocks_binary = "luarocks"
  local install_destination = M.root("rocks/")

  M.system({
    luarocks_binary,
    "--lua-version=5.1",
    "--tree=" .. install_destination,
    "make",
    rest_nvim_dir .. "/rest.nvim-scm-2.rockspec",
  })

  local sysname = vim.uv.os_uname().sysname:lower()
  local lib_extension = (sysname:find("windows") and "dll") or (sysname:find("darwin") and "dylib") or "so"
  local rocks_nvim_rtps = {
    { "lib", "lua", "5.1", "?." .. lib_extension },
    { "share", "lua", "5.1", "?.lua" },
    { "share", "lua", "5.1", "?", "init.lua" },
  }
  for _, rocks_nvim_rtp in ipairs(rocks_nvim_rtps) do
    local path = vim.fs.joinpath(install_destination, unpack(rocks_nvim_rtp))
    if path:match(".*" .. vim.pesc(lib_extension) .. "$") then
      package.cpath = package.cpath .. ";" .. path
    else
      package.path = package.path .. ";" .. path
    end
  end
  print(">> Finished making rest.nvim luarock")
end

---Downloads a plugin from a given url and registers it on the 'runtimepath'
---@param plugin_name PluginName
---@param plugin_url PluginUrl
function M.load_plugin(plugin_name, plugin_url)
  local package_root = M.root("plugins/")
  local install_destination = package_root .. plugin_name
  vim.opt.runtimepath:append(install_destination)

  if not vim.loop.fs_stat(package_root) then
    vim.fn.mkdir(package_root, "p")
  end

  -- If the plugin install path already exists, we don't need to clone it again.
  if not vim.loop.fs_stat(install_destination) then
    print(string.format('>> Downloading plugin "%s" to "%s"', plugin_name, install_destination))
    M.system({ "git", "clone", "--depth=1", plugin_url, install_destination })
  end
end

---@class SetupOpts
---@field rocks_config string Path to a `rocks.nvim` toml configuration file containing plugins

---Do the initial setup. Downloads plugins, ensures the minimal init does not pollute the filesystem by keeping
---everything self contained to the CWD of the minimal init file. Run prior to running tests, reproducing issues, etc.
---@param plugins? GitPlugins
function M.setup(plugins)
  plugins = plugins or {}

  vim.env.XDG_CONFIG_HOME = M.root("xdg/config")
  vim.env.XDG_DATA_HOME = M.root("xdg/data")
  vim.env.XDG_STATE_HOME = M.root("xdg/state")
  vim.env.XDG_CACHE_HOME = M.root("xdg/cache")

  local std_paths = {
    "cache",
    "data",
    "config",
  }

  for _, std_path in pairs(std_paths) do
    vim.fn.mkdir(vim.fn.stdpath(std_path), "p")
  end

  -- NOTE: Cleanup the xdg cache on exit so new runs of the minimal init doesn't share any previous state, e.g. shada
  vim.api.nvim_create_autocmd("VimLeave", {
    callback = function()
      vim.fn.delete(M.root("xdg"), "rf")
    end,
  })

  -- Build our local lua rock for usage
  M.make_luarock()

  for plugin_name, plugin_url in pairs(plugins) do
    M.load_plugin(plugin_name, plugin_url)
  end
end

M.setup({
  plenary = "https://github.com/nvim-lua/plenary.nvim.git",
  treesitter = "https://github.com/nvim-treesitter/nvim-treesitter.git",
})

-- WARN: Do all plugin setup, test runs, reproductions, etc. AFTER calling setup with a list of plugins!
-- Basically, do all that stuff AFTER this line.

require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "xml", "http", "json", "graphql" },
  sync_install = true,
})

-- Ensure we can use `rest.nvim` by registering it on the rtp
-- vim.opt.runtimepath:append(rest_nvim_dir)
require("rest-nvim").setup({})
