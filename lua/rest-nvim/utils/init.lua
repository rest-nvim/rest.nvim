local M = {}

-- has_value checks if the provided table contains the provided string using a regex
-- @param tbl Table to iterate over
-- @param str String to search in the table
M.has_value = function(tbl, str)
	for _, element in ipairs(tbl) do
		if string.find(str, element) then
			return true
		end
	end
	return false
end

-- tbl_to_str recursively converts the provided table into a json string
-- @param tbl Table to convert into a String
-- @param json If the string should use a key:value syntax
M.tbl_to_str = function(tbl, json)
	if not json then
		json = false
	end
	local result = '{'
	for k, v in pairs(tbl) do
		-- Check the key type (ignore any numerical keys - assume its an array)
		if type(k) == 'string' then
			result = result .. '"' .. k .. '"' .. ':'
		end
		-- Check the value type
		if type(v) == 'table' then
			result = result .. M.tbl_to_str(v)
		elseif type(v) == 'boolean' then
			result = result .. tostring(v)
		elseif type(v) == 'number' then
			result = result .. v
		else
			result = result .. '"' .. v .. '"'
		end
		if json then
			result = result .. ':'
		else
			result = result .. ','
		end
	end
	-- Remove leading commas from the result
	if result ~= '' then
		result = result:sub(1, result:len() - 1)
	end
	return result .. '}'
end

-- Just a split function because Lua does not have this, nothing more
M.split = function(str, sep)
	if sep == nil then
		sep = '%s'
	end

	local str_tbl = {}
	for match in string.gmatch(str, '([^' .. sep .. ']+)') do
		table.insert(str_tbl, match)
	end

	return str_tbl
end

-- iter_lines returns an iterator
-- @param str String to iterate over
M.iter_lines = function(str)
	-- If the string does not have a newline at the end then add it manually
	if str:sub(-1) ~= '\n' then
		str = str .. '\n'
	end

	return str:gmatch('(.-)\n')
end

-- char_to_hex returns the provided character as its hex value, e.g., "[" is
-- converted to "%5B"
-- @param char The character to convert
M.char_to_hex = function(char)
	return string.format('%%%02X', string.byte(char))
end

-- encode_url encodes the given URL
-- @param url The URL to encode
M.encode_url = function(url)
	if url == nil then
		error('You must need to provide an URL to encode')
	end

	url = url:gsub('\n', '\r\n')
	-- Encode characters but exclude `.`, `_`, `-`, `:`, `/`, `?`, `&`, `=`, `~`
	url = string.gsub(url, '([^%w _ %- . : / ? & = ~])', M.char_to_hex)
	url = url:gsub(' ', '+')
	return url
end

-- http_status returns the status code and the meaning, e.g. 200 OK
-- see https://httpstatuses.com/ for reference
M.http_status = function(code)
	-- NOTE: this table does not cover all the statuses _yet_
	local status_meaning = {
		-- 1xx codes (Informational)
		[100] = 'Continue',
		[101] = 'Switching Protocols',
		[102] = 'Processing',

		-- 2xx codes (Success)
		[200] = 'OK',
		[201] = 'Created',
		[202] = 'Accepted',
		[203] = 'Non-authorative Information',
		[204] = 'No Content',
		[205] = 'Reset Content',
		[206] = 'Partial Content',
		[207] = 'Multi-Status',
		[208] = 'Already Reported',
		[226] = 'IM Used',

		-- 3xx codes (Redirection)
		[300] = 'Multiple Choices',
		[301] = 'Moved Permanently',
		[302] = 'Found',
		[303] = 'See Other',
		[304] = 'Not Modified',
		[305] = 'Use Proxy',
		[307] = 'Temporary Redirect',
		[308] = 'Permanent Redirect',

		-- 4xx codes (Client Error)
		[400] = 'Bad Request',
		[401] = 'Unauthorized',
		[403] = 'Forbidden',
		[404] = 'Not Found',
		[405] = 'Method Not Allowed',
		[406] = 'Not Acceptable',
		[407] = 'Proxy Authentication Required',
		[408] = 'Request Timeout',
		[409] = 'Conflict',
		[410] = 'Gone',
		[411] = 'Length Required',
		[412] = 'Precondition Failed',
		[413] = 'Payload Too Large',
		[414] = 'Request-URI Too Long',
		[415] = 'Unsupported Media Type',
		[416] = 'Requested Range Not Satisfiable',
		[417] = 'Expectation Failed',
		[418] = "I'm a teapot",
		[421] = 'Misdirected Request',
		[422] = 'Unprocessable Entity',
		[423] = 'Locked',
		[424] = 'Failed Dependency',
		[426] = 'Upgrade Required',
		[428] = 'Precondition Required',
		[429] = 'Too Many Requests',
		[431] = 'Request Header Fields Too Large',
		[444] = 'Connection Closed Without Response',
		[451] = 'Unavailable For Legal Reasons',
		[499] = 'Client Closed Request',

		-- 5xx codes (Server Error)
		[500] = 'Internal Server Error',
		[501] = 'Not Implemented',
		[502] = 'Bad Gateway',
		[503] = 'Service Unavailable',
		[504] = 'Gateway Timeout',
		[505] = 'HTTP Version Not Supported',
		[506] = 'Variant Also Negotiates',
		[507] = 'Insufficient Storage',
		[508] = 'Loop Detected',
		[510] = 'Not Extended',
		[511] = 'Network Authentication Required',
		[599] = 'Network Connect Timeout Error',
	}

	-- If the code is covered in the status_meaning table
	if status_meaning[code] ~= nil then
		return tostring(code) .. ' ' .. status_meaning[code]
	end

	return tostring(code) .. ' Unknown Status Meaning'
end

return M
