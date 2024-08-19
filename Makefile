.PHONY: lint format test docgen
.SILENT: docgen

lint:
	luacheck .

format:
	stylua .

test:
	LUA_PATH="$(shell luarocks path --lr-path --lua-version 5.1 --local)" \
	LUA_CPATH="$(shell luarocks path --lr-cpath --lua-version 5.1 --local)" \
	luarocks test --local --lua-version 5.1

docgen:
	lemmy-help lua/rest-nvim/commands.lua > doc/rest-nvim-commands.txt
	lemmy-help lua/rest-nvim/config/init.lua > doc/rest-nvim-config.txt
	lemmy-help lua/rest-nvim/cookie_jar.lua > doc/rest-nvim-cookies.txt
	lemmy-help lua/rest-nvim/api.lua lua/rest-nvim/client/init.lua lua/rest-nvim/script/init.lua lua/rest-nvim/ui/result.lua lua/rest-nvim/utils.lua > doc/rest-nvim-api.txt
	lemmy-help lua/rest-nvim/client/curl/cli.lua lua/rest-nvim/client/curl/utils.lua > doc/rest-nvim-client-curl.txt
