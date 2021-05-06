if exists("b:current_syntax") | finish | endif

let b:current_syntax = "httpResult"

syn match httpResultComment "^#\+"
syn keyword httpResultTitle GET POST PATCH PUT HEAD DELETE nextgroup=httpResultPath
syn match httpResultPath    ".*$" contained

syn include @json syntax/json.vim
syn region jsonBody start="\v^\{" end="\v\S+\}$" contains=@json keepend

hi link httpResultComment Comment
hi link httpResultTitle   Type
hi link httpResultPath    Title
