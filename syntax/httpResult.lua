if vim.fn.exists("b:current_syntax") == 1 then
  return
end

local function syntax(kind, group, rhs)
  vim.cmd(string.format("syn %s %s %s", kind, group, rhs))
end

local function hl_link(lhs, rhs)
  local ns = vim.api.nvim_create_namespace("rest.result")
  vim.api.nvim_set_hl(ns, lhs, { link = rhs })
end

syntax("match",   "httpResultComment", [["\v^#.*$"]])
syntax("match",   "httpResultPath",    [[/.*$/ contained]])
syntax("keyword", "httpResultTitle",   [[GET POST PATCH PUT HEAD DELETE nextgroup=httpResultPath]])

syntax("match", "httpResultField",     [[/^\(\w\)[^:]\+:/he=e-1]])
syntax("match", "httpResultDateField", [[/^[Dd]ate:/he=e-1    nextgroup=httpResultDate]])
syntax("match", "httpResultDateField", [[/^[Ee]xpires:/he=e-1 nextgroup=httpResultDate]])
syntax("match", "httpResultDate",      [[/.*$/ contained]])

syntax("match",  "httpResult200",      [[/2\d\d.*$/ contained]])
syntax("match",  "httpResult300",      [[/3\d\d.*$/ contained]])
syntax("match",  "httpResult400",      [[/4\d\d.*$/ contained]])
syntax("match",  "httpResult500",      [[/5\d\d.*$/ contained]])
syntax("region", "httpResultHeader",   [[start=+^HTTP/+ end=+ + nextgroup=httpResult200,httpResult300,httpResult400,httpResult500]])

syntax("match",  "httpResultNumber",   [[/\v[ =]@1<=[0-9]*.?[0-9]+[ ,;&\n]/he=e-1]])
syntax("region", "httpResultString",   [[start=/\vr?"/ end=/\v"/]])


hl_link("httpResultComment",   "Comment")
hl_link("httpResultTitle",     "Type")
hl_link("httpResultPath",      "httpTSURI")
hl_link("httpResultField",     "Identifier")
hl_link("httpResultDateField", "Identifier")
hl_link("httpResultDate",      "String")
hl_link("httpResultString",    "String")
hl_link("httpResultNumber",    "Number")
hl_link("httpResultHeader",    "Type")
hl_link("httpResult200",       "String")
hl_link("httpResult300",       "Function")
hl_link("httpResult400",       "Number")
hl_link("httpResult500",       "Number")

vim.b.current_syntax = "httpResult"
