; Keywords
(scheme) @module

; Methods
(method) @function.method

; Constants
(const_spec) @constant

; Headers
(header
  name: (name) @constant)

; Variables
(variable_declaration
  name: (identifier) @variable)

(variable_declaration
  value: (number) @number)

(variable_declaration
  value: (boolean) @boolean)

(variable_declaration
  value: (string) @string)

; Fields
(pair
  name: (identifier) @variable.member)

; URL / Host
(host) @string.special.url

(host
  (identifier) @string.special.url)

(path
  (identifier) @string.special.url)

; Parameters
(query_param
  (key) @variable.parameter)

; Operators
[
  "="
  "?"
  "&"
  "@"
  "<"
] @operator

; Literals
(target_url) @string.special.url

(http_version) @constant

(string) @string

(number) @number

(boolean) @boolean

; Punctuation
[
  "{{"
  "}}"
] @punctuation.bracket

":" @punctuation.delimiter

; external JSON body
(external_body
  file_path: (path) @string.special.path)

; Comments
(comment) @comment @spell
