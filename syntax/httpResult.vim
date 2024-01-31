if exists("b:current_syntax") | finish | endif

syn match   httpResultComment "\v^#.*$"
syn keyword httpResultMethod OPTIONS GET HEAD POST PUT DELETE TRACE CONNECT nextgroup=httpResultPath
syn match   httpResultPath  /.*$/hs=s+1 contained

syn match httpResultField /^\(\w\)[^:]\+:/he=e-1
syn match httpResultDateField /^[Dd]ate:/he=e-1    nextgroup=httpResultDate
syn match httpResultDateField /^[Ee]xpires:/he=e-1 nextgroup=httpResultDate
syn match httpResultDate /.*$/ contained

syn region httpResultHeader start=+^HTTP/+ end=+ + nextgroup=httpResult200,httpResult300,httpResult400,httpResult500
syn match  httpResult200 /2\d\d.*$/ contained
syn match  httpResult300 /3\d\d.*$/ contained
syn match  httpResult400 /4\d\d.*$/ contained
syn match  httpResult500 /5\d\d.*$/ contained

syn region httpResultString start=/\vr?"/ end=/\v"/
syn match  httpResultNumber /\v[ =]@1<=[0-9]*.?[0-9]+[ ,;&\n]/he=e-1

hi link httpResultComment   @comment
hi link httpResultMethod    @type
hi link httpResultPath      @text.uri
hi link httpResultField     @constant
hi link httpResultDateField @constant
hi link httpResultDate      @attribute
hi link httpResultString    @string
hi link httpResultNumber    @number
hi link httpResultHeader    @constant
hi link httpResult200       Msg
hi link httpResult300       MoreMsg
hi link httpResult400       WarningMsg
hi link httpResult500       ErrorMsg

let b:current_syntax = "httpResult"
