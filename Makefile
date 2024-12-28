.PHONY: lint format test docgen doc
.SILENT: docgen

lint:
	luacheck .

format:
	stylua .

test:
	luarocks test --local --lua-version 5.1 --dev
