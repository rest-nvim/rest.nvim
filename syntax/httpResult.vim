if exists("b:current_syntax") | finish | endif

syn match httpResultComment  "\v^#.*$"
syn keyword httpResultTitle  GET POST PATCH PUT HEAD DELETE nextgroup=httpResultPath
syn match httpResultPath     ".*$" contained
syn match httpResultField    /^\(\w\)[^:]\+:/he=e-1

syn include @json syntax/json.vim
syn region jsonBody start="\v^\{" end="\v\S+\}$" contains=@json keepend

hi link httpResultComment  Comment
hi link httpResultTitle    Type
hi link httpResultPath     Title
hi link httpResultField    Variable

let b:current_syntax = "httpResult"
