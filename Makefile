lint:
	luacheck .

format:
	stylua .

test:
	# 
	busted tests/test.lua
