; Keywords

(scheme) @constant

; Methods

(method) @method

; Constants

(const_spec) @constant

; URL
(host) @text.uri

; Headers

(header
  name: (name) @constant)

; Variables

(identifier) @variable

; Fields

(pair name: (identifier) @field)

; Parameters

(query_param (key) @parameter)

; Operators

[
  "="
  "?"
  "&"
  "@"
] @operator

; Literals

(string) @string

(target_url) @text.uri

(number) @number

; (boolean) @boolean

(null) @constant.builtin

; Punctuation

[ "{{" "}}" ] @punctuation.bracket

[
  ":"
] @punctuation.delimiter

; Comments

(comment) @comment @spell

; Errors

(ERROR) @error

