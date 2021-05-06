if exists('b:current_syntax') | finish | endif

syn match httpUrl "\(https\?:\/\{2}\)\?\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z][-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}\(:[0-9]\{1,5}\)\?\S*"

syn keyword httpCommentKeyword TODO contained
syn match httpComment          "\v^#.*$" contains=httpCommentKeyword

syn keyword httpMethod GET POST PATCH PUT HEAD DELETE nextgroup=httpPath
syn match httpPath     ".*$" contained

syn match httpParamSection   "^.*[=:][^/]" contains=httpParamSeparator
syn match httpParamSeparator "[:]" contained

syn match httpVarSection   "^\(VAR\)[=:]" nextgroup=httpVarKey skipwhite
syn match httpVarKey       "[^:]\+" contained nextgroup=httpVarSeparator skipwhite
syn match httpVarSeparator "[=:]" contained

syn include @json syntax/json.vim
syn region jsonBody start="\v\{" end="\v\}$" contains=@json keepend


hi link httpComment         Comment
hi link httpCommentKeyword  Todo
hi link httpUrl             Title
hi link httpMethod          Type
hi link httpPath            Title
hi link httpVarSection      Type
hi link httpVarKey          Constant
hi link httpVarSeparator    Todo
hi link httpParamSection    Constant
hi link httpParamSeparator  Todo

let b:current_syntax = 'http'
