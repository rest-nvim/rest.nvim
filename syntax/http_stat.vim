if exists("b:current_syntax") | finish | endif

syntax match httpStatField "^\s*\zs.\{-}\ze:"
syntax match httpStatValue ": \zs.*$"

highlight link httpStatField Identifier
highlight link httpStatValue String

let b:current_syntax = "http_stat"
