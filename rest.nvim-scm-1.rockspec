local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "rest.nvim"
version = _MODREV .. _SPECREV

description = {
	summary = "A fast Neovim http client written in Lua",
	labels = { "neovim", "rest"},
	detailed = [[
    rest.nvim makes use of a curl wrapper implemented in pure Lua in plenary.nvim so, in other words, rest.nvim is a curl wrapper so you don't have to leave Neovim!
   ]],
	homepage = "https://github.com/NTBBloodbath/rest.nvim",
	license = "MIT",
}

dependencies = {
	"lua >= 5.1, < 5.4",
}

source = {
	url = "http://github.com/NTBBloodbath/rest.nvim/archive/v" .. _MODREV .. ".zip",
	dir = "rest.nvim-" .. _MODREV,
}

if _MODREV == "scm" then
	source = {
		url = "git://github.com/NTBBloodbath/rest.nvim",
	}
end

build = {
   type = "builtin",
   copy_directories = {
	   'plugin'
   }
}
