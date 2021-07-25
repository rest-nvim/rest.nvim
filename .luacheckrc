-- Use lua52 so we will no receive errors regarding to goto statements
std = 'lua52'

-- Rerun tests only if their modification time changed
cache = true

ignore = {
	'631', -- max_line_length
}

read_globals = {
	'vim',
}

-- vim: ft=lua
