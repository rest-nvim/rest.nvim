lint:
	luacheck .

format:
	stylua .

test:
	# possible args to test_directory: sequential=true,keep_going=false
	# minimal.vim is generated when entering the flake, aka `nix develop ./contrib`
	nvim --headless -u minimal.vim -c "lua require('plenary.test_harness').test_directory('.', {minimal_init='minimal.vim'})"

