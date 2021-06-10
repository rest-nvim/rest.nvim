if exists('b:current_syntax') | finish | endif

syn match httpUrl "\(https\?:\/\{2}\)\?\(\w\+\(:\w\+\)\?@\)\?\([A-Za-z][-_0-9A-Za-z]*\.\)\{1,}\(\w\{2,}\.\?\)\{1,}\(:[0-9]\{1,5}\)\?\S*"

syn keyword httpCommentKeyword TODO NOTE FIXME BUG contained
syn match   httpComment        "\v^#.*$" contains=httpCommentKeyword

syn keyword httpMethod GET POST PATCH PUT HEAD DELETE nextgroup=httpPath
syn match   httpPath   ".*$" contained

syn match httpHeaderKey       "^\(\w\)[^:]\+" nextgroup=httpHeaderSeparator skipwhite
syn match httpHeaderSeparator "[=:]" contained

syn include @json syntax/json.vim
syn region  jsonBody start="\v^\{" end="\v^\}$" contains=@json keepend


hi link httpComment         Comment
hi link httpCommentKeyword  Todo
hi link httpUrl             Title
hi link httpMethod          Type
hi link httpPath            Title
hi link httpHeaderKey       Identifier
hi link httpHeaderSeparator Delimiter

let b:current_syntax = 'http'
