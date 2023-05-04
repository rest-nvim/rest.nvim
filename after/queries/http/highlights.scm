; Keywords

(scheme) @namespace

; Methods

(method) @method

; Constants

(const_spec) @constant

; Headers

(header
  name: (name) @constant)

; Variables

(identifier) @variable

; Fields

(pair name: (identifier) @field)

; URL / Host
(host) @text.uri
(host (identifier) @text.uri)
(path (identifier) @text.uri)

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

