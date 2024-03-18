-- Use lua52 so we will no receive errors regarding to goto statements
std = "lua52+busted"

-- Rerun tests only if their modification time changed
cache = true

ignore = {
  "122", -- Setting a read-only field of a global variable
  "631", -- Line is too long
}

read_globals = {
  "vim",
}

-- vim: ft=lua
