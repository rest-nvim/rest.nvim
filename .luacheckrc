std = "luajit+busted"

-- Rerun tests only if their modification time changed
cache = true

ignore = {
  "122", -- Setting a read-only field of a global variable
  "631", -- Line is too long
  "21/_.*", -- Unused variable starting with underscore
}

read_globals = {
  "vim",
}
