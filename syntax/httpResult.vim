if exists("b:current_syntax") | finish | endif

syn match   httpResultComment "\v^#.*$"
syn keyword httpResultTitle GET POST PATCH PUT HEAD DELETE nextgroup=httpResultPath
syn match   httpResultPat  /.*$/ contained

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

hi link httpResultComment   Comment
hi link httpResultTitle     Type
hi link httpResultPath      httpTSURI
hi link httpResultField     Identifier
hi link httpResultDateField Identifier
hi link httpResultDate      String
hi link httpResultString    String
hi link httpResultNumber    Number
hi link httpResultHeader    Type
hi link httpResult200       String
hi link httpResult300       Function
hi link httpResult400       Number
hi link httpResult500       Number

let b:current_syntax = "httpResult"
