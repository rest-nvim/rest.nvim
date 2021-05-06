local vim = vim
local api, fn = vim.api, vim.fn

local curl = require('plenary.curl')
local utils = require('rest-nvim.utils')

-- get_or_create_buf checks if there is already a buffer with the rest run results
-- and if the buffer does not exists, then create a new one
local function get_or_create_buf()
	local tmp_name = 'rest_nvim_results'

	-- Check if the file is already loaded in the buffer
	local existing_bufnr = fn.bufnr(tmp_name)
	if existing_bufnr ~= -1 then
		-- Set modifiable
		api.nvim_buf_set_option(existing_bufnr, 'modifiable', true)
		-- Delete buffer content
		api.nvim_buf_set_lines(
			existing_bufnr,
			0,
			api.nvim_buf_line_count(existing_bufnr) - 1,
			false,
			{}
		)

		-- Make sure the filetype of the buffer is httpResult so it will be highlighted
		api.nvim_buf_set_option(existing_bufnr, 'ft', 'httpResult')

		return existing_bufnr
	end

	-- Create new buffer
	local new_bufnr = api.nvim_create_buf(false, 'nomodeline')
	api.nvim_buf_set_name(new_bufnr, tmp_name)
	api.nvim_buf_set_option(new_bufnr, 'ft', 'httpResult')

	return new_bufnr
end

-- parse_url returns a table with the method of the request and the URL
-- @param stmt the request statement, e.g., POST http://localhost:3000/foo
local function parse_url(stmt)
	local parsed = utils.split(stmt, ' ')
	return {
		method = parsed[1],
		url = parsed[2],
	}
end

-- go_to_line moves the cursor to the desired line in the provided buffer
-- @param bufnr Buffer number, a.k.a id
-- @param line the desired cursor position
local function go_to_line(bufnr, line)
	api.nvim_buf_call(bufnr, function()
		fn.cursor(line, 1)
	end)
end

-- get_json retrieves the json lines in the buffer and then returns a json table
-- @param term The term to search, e.g., BODY
-- @param bufnr Buffer number, a.k.a id
-- @param stop_line Line to stop searching
-- @param query_line Line to set cursor position
local function get_json(term, bufnr, stop_line, query_line)
	local json = nil
	local start_line = 0
	local end_line = 0

	start_line = fn.search(term .. ' {', '', stop_line)
	end_line = fn.search('}', 'n', stop_line)

	if start_line > 0 then
		local json_string = ''
		local json_lines =
			api.nvim_buf_get_lines(bufnr, start_line, end_line - 1, false)
		for _, v in ipairs(json_lines) do
			json_string = json_string .. v
		end

		json_string = '{' .. json_string .. '}'
		json = fn.json_decode(json_string)
	end

	go_to_line(bufnr, query_line)
	return json
end

-- get_array retrieves the array elements in the desired line and then returns a
-- lua table with its elements
-- @param term The term to search, e.g. AUTH
-- @param bufnr Buffer number, a.k.a id
-- @param stop_line Line to stop searching
-- @param query_line Line to set cursor position
local function get_array(term, bufnr, stop_line, query_line)
	local array = {}
	local start_line = 0
	local end_line = 0

	start_line = fn.search(term .. ' {', '', stop_line)
	end_line = fn.search('}', 'n', stop_line)

	if start_line > 0 then
		local array_elements =
			api.nvim_buf_get_lines(bufnr, start_line, end_line - 1, false)
		for _, element in ipairs(array_elements) do
			table.insert(array, element)
		end
	end

	go_to_line(bufnr, query_line)
	return array
end

-- curl_cmd runs curl with the passed options, gets or creates a new buffer
-- and then the results are printed to the recently obtained/created buffer
-- @param opts curl arguments
local function curl_cmd(opts)
	local res = curl[opts.method](opts)
	local res_bufnr = get_or_create_buf()
	local parsed_url = parse_url(fn.getline('.'))
	local json_body = false

	-- Check if the content-type is "application/json" so we can format the JSON
	-- output later
	for _, header in ipairs(res.headers) do
		if string.find(header, 'application/json') then
			json_body = true
			break
		end
	end

	--- Add metadata into the created buffer (status code, date, etc)
	local line_count = api.nvim_buf_line_count(res_bufnr) - 1
	-- Request statement (METHOD URL)
	api.nvim_buf_set_lines(
		res_bufnr,
		line_count,
		line_count,
		false,
		{ parsed_url.method .. ' ' .. parsed_url.url }
	)
	-- Status code and its meaning, e.g. HTTP/1.1 200 OK
	line_count = api.nvim_buf_line_count(res_bufnr)
	api.nvim_buf_set_lines(
		res_bufnr,
		line_count,
		line_count,
		false,
		{ 'HTTP/1.1 ' .. utils.http_status(res.status) }
	)
	-- Headers, e.g. Content-Type: application/json
	for _, header in ipairs(res.headers) do
		line_count = api.nvim_buf_line_count(res_bufnr)
		api.nvim_buf_set_lines(res_bufnr, line_count, line_count, false, { header })
	end

	--- Add the curl command results into the created buffer
	for line in utils.iter_lines(res.body) do
		if json_body then
			-- Format JSON output and then add it into the buffer
			-- line by line because Vim doesn't allow strings with newlines
			local out = fn.system("echo '" .. line .. "' | jq .")
			for _, _line in ipairs(utils.split(out, '\n')) do
				line_count = api.nvim_buf_line_count(res_bufnr) - 1
				api.nvim_buf_set_lines(
					res_bufnr,
					line_count,
					line_count,
					false,
					{ _line }
				)
			end
		else
			line_count = api.nvim_buf_line_count(res_bufnr) - 1
			api.nvim_buf_set_lines(
				res_bufnr,
				line_count,
				line_count,
				false,
				{ line }
			)
		end
	end

	-- Only open a new split if the buffer is not loaded into the current window
	if fn.bufwinnr(res_bufnr) == -1 then
		vim.cmd([[vert sb]] .. res_bufnr)
		-- Set unmodifiable state
		api.nvim_buf_set_option(res_bufnr, 'modifiable', false)
	end

	api.nvim_buf_call(res_bufnr, function()
		fn.cursor(1, 1) -- Send cursor to buffer start again
	end)
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
local function run()
	local bufnr = api.nvim_win_get_buf(0)
	local parsed_url = parse_url(fn.getline('.'))
	local last_query_line_number = fn.line('.')

	local next_query =
		fn.search(
			'GET\\|POST\\|PUT\\|PATCH\\|DELETE',
			'n',
			fn.line('$')
		)
	next_query = next_query > 1 and next_query or fn.line('$')

	local headers =
		get_json('HEADERS', bufnr, next_query, last_query_line_number)
	local body = get_json('BODY', bufnr, next_query, last_query_line_number)
	local queries =
		get_json('QUERIES', bufnr, next_query, last_query_line_number)
	local form = get_json('FORM', bufnr, next_query, last_query_line_number)
	local auth =
		get_array('AUTH', bufnr, next_query, last_query_line_number)

	curl_cmd({
		method = parsed_url.method:lower(),
		url = parsed_url.url,
		query = queries,
		headers = headers,
		body = body,
		form = form,
		auth = auth,
	})

	go_to_line(bufnr, last_query_line_number)
end

return {
	run = run,
}
