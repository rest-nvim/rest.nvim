if vim.fn.has("nvim-0.9.0") ~= 1 then
  vim.notify_once("[rest.nvim] rest.nvim requires at least Neovim >= 0.9 in order to work")
  return
end

if vim.g.loaded_rest_nvim then
  return
end

--- Dependencies management ---
-------------------------------
-- This variable is going to hold the dependencies state (whether they are found or not),
-- to be used later by the `health.lua` module
local rest_nvim_deps = {}

-- Locate dependencies
local dependencies = {
  ["nvim-nio"] = "rest.nvim will not work asynchronously",
  ["nvim-treesitter"] = "rest.nvim parsing will not work",
  ["lua-curl"] = "Default HTTP client won't work",
  xml2lua = "rest.nvim will be completely unable to use XML bodies in your requests",
  mimetypes = "rest.nvim will be completely unable to recognize the file type of external body files",
}
for dep, err in pairs(dependencies) do
  local found_dep
  -- Both nvim-nio and lua-curl has a different Lua module name
  if dep == "nvim-nio" then
    found_dep = package.searchpath("nio", package.path)
  elseif dep == "lua-curl" then
    found_dep = package.searchpath("cURL.safe", package.path)
  else
    found_dep = package.searchpath(dep, package.path)
  end

  -- If the dependency could not be find in the Lua package.path then try to load it using pcall
  -- in case it has been installed through a regular plugin manager and not rocks.nvim
  if not found_dep then
    local found_dep2
    -- Both nvim-nio and lua-curl has a different Lua module name
    if dep == "nvim-nio" then
      found_dep2 = pcall(require, "nio")
    elseif dep == "lua-curl" then
      found_dep2 = pcall(require, "cURL.safe")
    else
      found_dep2 = pcall(require, dep)
    end

    rest_nvim_deps[dep] = {
      found = false,
      error = err,
    }
    if not found_dep2 then
      vim.notify("[rest.nvim] Dependency '" .. dep .. "' was not found. " .. err, vim.log.levels.ERROR)
    else
      rest_nvim_deps[dep] = {
        found = true,
        error = err,
      }
    end
  else
    rest_nvim_deps[dep] = {
      found = true,
      error = err,
    }
  end
end
vim.g.rest_nvim_deps = rest_nvim_deps

vim.g.loaded_rest_nvim = true
