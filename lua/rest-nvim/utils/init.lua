local M = {}

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

-- http_status returns the status code and the meaning, e.g. 200 OK
-- see https://httpstatuses.com/ for reference
M.http_status = function(code)
	-- NOTE: this table does not cover all the statuses _yet_
	local status_meaning = {
		-- 2xx codes (Success)
		[200] = 'OK',
		[201] = 'Created',
		[202] = 'Accepted',
		[203] = 'Non-authorative Information',
		[204] = 'No Content',
		[205] = 'Reset Content',
		[206] = 'Partial Content',

		-- 3xx codes (Redirection)
		[300] = 'Multiple Choices',
		[301] = 'Moved Permanently',
		[302] = 'Found',
		[307] = 'Temporary Redirect',
		[308] = 'Permanent Redirect',

		-- 4xx codes (Client Error)
		[400] = 'Bad Request',
		[401] = 'Unauthorized',
		[403] = 'Forbidden',
		[404] = 'Not Found',
		[405] = 'Method Not Allowed',
		[408] = 'Request Timeout',

		-- 5xx codes (Server Error)
		[500] = 'Internal Server Error',
		[501] = 'Not Implemented',
		[502] = 'Bad Gateway',
		[503] = 'Service Unavailable',
		[504] = 'Gateway Timeout',
	}

	-- If the code is covered in the status_meaning table
	if status_meaning[code] ~= nil then
		return tostring(code) .. ' ' .. status_meaning[code]
	end

	return tostring(code) .. ' Unknown Status Meaning'
end

return M
