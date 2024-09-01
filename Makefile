.PHONY: lint format test docgen doc
.SILENT: docgen

lint:
	luacheck .

format:
	stylua .

test:
	# TODO: install tree-sitter-http as a test dependency using nix
	# or version it appart from NURR
	LUA_PATH="$(shell luarocks path --lr-path --lua-version 5.1 --local)" \
	LUA_CPATH="$(shell luarocks path --lr-cpath --lua-version 5.1 --local)" \
	luarocks install --local --lua-version 5.1 --dev tree-sitter-http
	LUA_PATH="$(shell luarocks path --lr-path --lua-version 5.1 --local)" \
	LUA_CPATH="$(shell luarocks path --lr-cpath --lua-version 5.1 --local)" \
	luarocks test --local --lua-version 5.1 --dev
