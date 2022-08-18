local MAJOR, REV = "scm", "-1"
rockspec_format = "3.0"
package = "rest.nvim"
version = MAJOR .. REV

description = {
	summary = "A fast Neovim http client written in Lua",
	labels = { "neovim", "rest"},
	detailed = [[
    rest.nvim makes use of a curl wrapper implemented in pure Lua in plenary.nvim so, in other words, rest.nvim is a curl wrapper so you don't have to leave Neovim!
   ]],
	homepage = "https://github.com/rest-nvim/rest.nvim",
	license = "MIT",
}

dependencies = {
	"lua >= 5.1, < 5.4",
    "plenary.nvim",
}

source = {
	url = "http://github.com/rest-nvim/rest.nvim/archive/v" .. MAJOR .. ".zip",
	dir = "rest.nvim-" .. MAJOR,
}

if MAJOR == "scm" then
	source = {
		url = "git://github.com/rest-nvim/rest.nvim",
	}
end

build = {
   type = "builtin",
   copy_directories = {
	   'plugin'
   }
}
