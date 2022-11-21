lint:
	luacheck .

format:
	stylua .

test:
	# 
	# nvim --headless --noplugin -u scripts/minimal.vim -c "PlenaryBustedDirectory tests/plenary/ {minimal_init = 'tests/minimal_init.vim'}"
	nvim --headless --noplugin -u tests/minimal.vim -c "PlenaryBustedDirectory tests/plenary/ {minimal_init = 'tests/minimal_init.vim'}"
	busted tests/test.lua
