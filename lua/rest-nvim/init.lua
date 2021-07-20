local rest = {}

local curl = require('plenary.curl')
local path = require('plenary.path')
local utils = require('rest-nvim.utils')

-- setup is needed for enabling syntax highlighting for http files
rest.setup = function()
	if vim.fn.expand('%:e') == 'http' then
		vim.api.nvim_buf_set_option('%', 'filetype', 'http')
	end
end

-- get_or_create_buf checks if there is already a buffer with the rest run results
-- and if the buffer does not exists, then create a new one
local function get_or_create_buf()
	local tmp_name = 'rest_nvim_results'

	-- Check if the file is already loaded in the buffer
	local existing_bufnr = vim.fn.bufnr(tmp_name)
	if existing_bufnr ~= -1 then
		-- Set modifiable
		vim.api.nvim_buf_set_option(existing_bufnr, 'modifiable', true)
		-- Delete buffer content
		vim.api.nvim_buf_set_lines(
			existing_bufnr,
			0,
			vim.api.nvim_buf_line_count(existing_bufnr) - 1,
			false,
			{}
		)

		-- Make sure the filetype of the buffer is httpResult so it will be highlighted
		vim.api.nvim_buf_set_option(existing_bufnr, 'ft', 'httpResult')

		return existing_bufnr
	end

	-- Create new buffer
	local new_bufnr = vim.api.nvim_create_buf(false, 'nomodeline')
	vim.api.nvim_buf_set_name(new_bufnr, tmp_name)
	vim.api.nvim_buf_set_option(new_bufnr, 'ft', 'httpResult')

	return new_bufnr
end

-- parse_url returns a table with the method of the request and the URL
-- @param stmt the request statement, e.g., POST http://localhost:3000/foo
local function parse_url(stmt)
	local parsed = utils.split(stmt, ' ')
	return {
		method = parsed[1],
		-- Encode URL
		url = utils.encode_url(utils.replace_env_vars(parsed[2])),
	}
end

-- go_to_line moves the cursor to the desired line in the provided buffer
-- @param bufnr Buffer number, a.k.a id
-- @param line the desired cursor position
local function go_to_line(bufnr, line)
	vim.api.nvim_buf_call(bufnr, function()
		vim.fn.cursor(line, 1)
	end)
end

-- get_importfile returns in case of an imported file the absolute filename
-- @param bufnr Buffer number, a.k.a id
-- @param stop_line Line to stop searching
local function get_importfile(bufnr, stop_line)
	local import_line = 0
	import_line = vim.fn.search('^<', '', stop_line)
	if import_line > 0 then
		local fileimport_string = ''
		local fileimport_line = {}
		fileimport_line = vim.api.nvim_buf_get_lines(
			bufnr,
			import_line - 1,
			import_line,
			false
		)
		fileimport_string = fileimport_line[1]
		fileimport_string = string.gsub(fileimport_string, '<', '', 1)
			:gsub('^%s+', '')
			:gsub('%s+$', '')
		local fileimport_path = path.new(fileimport_string)
		if not fileimport_path:is_absolute() then
			local buffer_name = vim.api.nvim_buf_get_name(bufnr)
			local buffer_path = path.new(path.new(buffer_name):parent())
			fileimport_path = buffer_path:joinpath(fileimport_path)
		end
		return fileimport_path:absolute()
	end
	return nil
end

-- get_body retrieves the body lines in the buffer and then returns a raw table
-- if the body is not a JSON, otherwise, get_body will return a table
-- @param bufnr Buffer number, a.k.a id
-- @param stop_line Line to stop searching
-- @param query_line Line to set cursor position
-- @param json_body If the body is a JSON formatted POST request, false by default
local function get_body(bufnr, stop_line, query_line, json_body)
	if not json_body then
		json_body = false
	end
	local json = nil
	local start_line = 0
	local end_line = 0

	local importfile = get_importfile(bufnr, stop_line)
	if importfile ~= nil then
		return importfile
	end

	start_line = vim.fn.search('^{', '', stop_line)
	end_line = vim.fn.searchpair('{', '', '}', 'n', '', stop_line)

	if start_line > 0 then
		local json_string = ''
		local json_lines = {}
		json_lines = vim.api.nvim_buf_get_lines(
			bufnr,
			start_line,
			end_line - 1,
			false
		)

		for _, json_line in ipairs(json_lines) do
			-- Ignore commented lines with and without indent
			if not utils.contains_comments(json_line) then
				json_string = json_string .. utils.replace_env_vars(json_line)
			end
		end

		json = '{' .. json_string .. '}'
	end

	go_to_line(bufnr, query_line)

	return json
end

-- get_headers retrieves all the found headers and returns a lua table with them
-- @param bufnr Buffer number, a.k.a id
-- @param query_line Line to set cursor position
local function get_headers(bufnr, query_line)
	local headers = {}
	-- Set stop at end of buffer
	local stop_line = vim.fn.line('$')
	-- If we should stop iterating over the buffer lines
	local break_loops = false
	-- HTTP methods
	local http_methods = { 'GET', 'POST', 'PUT', 'PATCH', 'DELETE' }

	-- Iterate over all buffer lines
	for line = 1, stop_line do
		local start_line = vim.fn.search(':', '', stop_line)
		local end_line = start_line
		local next_line = vim.fn.getbufline(bufnr, line + 1)
		if break_loops then
			break
		end

		for _, next_line_content in pairs(next_line) do
			-- If the next line starts the request body then break the loop
			if next_line_content:find('^{') then
				break_loops = true
				break
			else
				local get_header = vim.api.nvim_buf_get_lines(
					bufnr,
					start_line - 1,
					end_line,
					false
				)

				for _, header in ipairs(get_header) do
					header = utils.split(header, ':')
					if
						header[1]:lower() ~= 'accept'
						-- If header key doesn't contains double quotes at the
						-- start, so we don't get body keys
						and not header[1]:find('^%s+"')
						-- If header key doesn't contains hashes,
						-- so we don't get commented headers
						and not utils.contains_comments(header[1])
						-- If header key doesn't contains HTTP methods,
						-- so we don't get the http method/url
						and not utils.has_value(http_methods, header[1])
					then
						headers[header[1]:lower()] = utils.replace_env_vars(
							header[2]
						)
					end
				end
			end
		end
	end

	go_to_line(bufnr, query_line)
	return headers
end

-- get_accept retrieves the Accept field and returns it as string
-- @param bufnr Buffer number, a.k.a id
-- @param query_line Line to set cursor position
local function get_accept(bufnr, query_line)
	local accept = nil
	-- Set stop at end of bufer
	local stop_line = vim.fn.line('$')

	-- Iterate over all buffer lines
	for _ = 1, stop_line do
		-- Case-insensitive search
		local start_line = vim.fn.search('\\cAccept:', '', stop_line)
		local end_line = start_line
		local accept_line = vim.api.nvim_buf_get_lines(
			bufnr,
			start_line - 1,
			end_line,
			false
		)

		for _, accept_data in pairs(accept_line) do
			-- Ignore commented lines with and without indent
			if not utils.contains_comments(accept_data) then
				accept = utils.split(accept_data, ':')[2]
			end
		end
	end

	go_to_line(bufnr, query_line)

	return accept
end

-- curl_cmd runs curl with the passed options, gets or creates a new buffer
-- and then the results are printed to the recently obtained/created buffer
-- @param opts curl arguments
local function curl_cmd(opts)
	local res = curl[opts.method](opts)
	if opts.dry_run then
		print(
			'[rest.nvim] Request preview:\n'
				.. 'curl '
				.. table.concat(res, ' ')
		)
		return
	end

	local res_bufnr = get_or_create_buf()
	local parsed_url = parse_url(vim.fn.getline('.'))
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
	-- Request statement (METHOD URL)
	vim.api.nvim_buf_set_lines(
		res_bufnr,
		0,
		0,
		false,
		{ parsed_url.method .. ' ' .. parsed_url.url }
	)
	-- HTTP version, status code and its meaning, e.g. HTTP/1.1 200 OK
	local line_count = vim.api.nvim_buf_line_count(res_bufnr)
	vim.api.nvim_buf_set_lines(
		res_bufnr,
		line_count,
		line_count,
		false,
		{ 'HTTP/1.1 ' .. utils.http_status(res.status) }
	)
	-- Headers, e.g. Content-Type: application/json
	vim.api.nvim_buf_set_lines(
		res_bufnr,
		line_count + 1,
		line_count + #res.headers,
		false,
		res.headers
	)

	--- Add the curl command results into the created buffer
	if json_body then
		-- format JSON body
		res.body = vim.fn.system('jq', res.body)
	end
	local lines = utils.split(res.body, '\n')
	line_count = vim.api.nvim_buf_line_count(res_bufnr) - 1
	vim.api.nvim_buf_set_lines(
		res_bufnr,
		line_count,
		line_count + #lines,
		false,
		lines
	)

	-- Only open a new split if the buffer is not loaded into the current window
	if vim.fn.bufwinnr(res_bufnr) == -1 then
		vim.cmd([[vert sb]] .. res_bufnr)
		-- Set unmodifiable state
		vim.api.nvim_buf_set_option(res_bufnr, 'modifiable', false)
	end

	vim.api.nvim_buf_call(res_bufnr, function()
		vim.fn.cursor(1, 1) -- Send cursor to buffer start again
	end)
end

-- run will retrieve the required request information from the current buffer
-- and then execute curl
rest.run = function(verbose)
	local bufnr = vim.api.nvim_win_get_buf(0)
	local parsed_url = parse_url(vim.fn.getline('.'))
	local last_query_line_number = vim.fn.line('.')

	local next_query = vim.fn.search(
		'GET\\|POST\\|PUT\\|PATCH\\|DELETE',
		'n',
		vim.fn.line('$')
	)
	next_query = next_query > 1 and next_query or vim.fn.line('$')

	local headers = get_headers(bufnr, last_query_line_number)

	local body
	-- If the header Content-Type was passed and it's application/json then return
	-- body as `-d '{"foo":"bar"}'`
	if
		headers ~= nil
		and headers['content-type'] ~= nil
		and string.find(headers['content-type'], 'application/json')
	then
		body = get_body(bufnr, next_query, last_query_line_number, true)
	else
		body = get_body(bufnr, next_query, last_query_line_number)
	end

	local accept = get_accept(bufnr, last_query_line_number)

	local success_req, req_err = pcall(curl_cmd, {
		method = parsed_url.method:lower(),
		url = parsed_url.url,
		headers = headers,
		accept = accept,
		raw_body = body,
		dry_run = verbose and verbose or false,
	})

	if not success_req then
		error(
			'[rest.nvim] Failed to perform the request.\nMake sure that you have entered the proper URL and the server is running.\n\nTraceback: '
				.. req_err,
			2
		)
	end
	go_to_line(bufnr, last_query_line_number)
end

return rest
