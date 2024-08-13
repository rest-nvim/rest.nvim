.PHONY: lint format test docgen
.SILENT: docgen

lint:
	luacheck .

format:
	stylua .

test:
	eval "$(shell luarocks path --no-bin)"
	luarocks test --local

docgen:
	lemmy-help lua/rest-nvim/commands.lua > doc/rest-nvim-commands.txt
	lemmy-help lua/rest-nvim/config/init.lua > doc/rest-nvim-config.txt
	lemmy-help lua/rest-nvim/cookie_jar.lua > doc/rest-nvim-cookies.txt
	lemmy-help lua/rest-nvim/script.lua > doc/rest-nvim-script.txt
	lemmy-help lua/rest-nvim/api.lua lua/rest-nvim/utils.lua > doc/rest-nvim-api.txt
	lemmy-help lua/rest-nvim/client/curl/cli.lua lua/rest-nvim/client/curl/utils.lua > doc/rest-nvim-client-curl.txt
