.PHONY: lint format docgen
.SILENT: docgen

lint:
	luacheck .

format:
	stylua .

docgen:
	lemmy-help lua/rest-nvim/client/curl.lua > doc/rest-nvim-curl.txt
	lemmy-help lua/rest-nvim/commands.lua > doc/rest-nvim-commands.txt
	lemmy-help lua/rest-nvim/config/init.lua > doc/rest-nvim-config.txt
	lemmy-help lua/rest-nvim/parser/dynamic_vars.lua lua/rest-nvim/parser/env_vars.lua lua/rest-nvim/parser/script_vars.lua lua/rest-nvim/parser/init.lua > doc/rest-nvim-parser.txt
	lemmy-help lua/rest-nvim/api.lua lua/rest-nvim/utils.lua lua/rest-nvim/functions.lua lua/rest-nvim/logger.lua lua/rest-nvim/result/init.lua lua/rest-nvim/result/winbar.lua lua/rest-nvim/result/help.lua > doc/rest-nvim-api.txt
