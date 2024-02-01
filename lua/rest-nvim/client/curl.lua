---@mod rest-nvim.client.curl rest.nvim cURL client
---
---@brief [[
---
--- rest.nvim cURL client implementation
---
---@brief ]]

local client = {}

local curl = require("cURL.safe")
local mimetypes = require("mimetypes")

local utils = require("rest-nvim.utils")
local script_vars = require("rest-nvim.parser.script_vars")

-- TODO: add support for running multiple requests at once for `:Rest run document`
-- TODO: add support for submitting forms in the `client.request` function
-- TODO: add support for submitting XML bodies in the `client.request` function

---Return the status code and the meaning of an curl error
---see man curl for reference
---@param code number The exit code of curl
---@return string
local function curl_error(code)
  local curl_error_dictionary = {
    [1] = "Unsupported protocol. This build of curl has no support for this protocol.",
    [2] = "Failed to initialize.",
    [3] = "URL malformed. The syntax was not correct.",
    [4] = "A feature or option that was needed to perform the desired request was not enabled or was explicitly disabled at build-time."
      .. "To make curl able to do this, you probably need another build of libcurl!",
    [5] = "Couldn't resolve proxy. The given proxy host could not be resolved.",
    [6] = "Couldn't resolve host. The given remote host was not resolved.",
    [7] = "Failed to connect to host.",
    [8] = "Weird server reply. The server sent data curl couldn't parse.",
    [9] = "FTP access denied. The server denied login or denied access to the particular resource or directory you wanted to reach. Most often you tried to change to a directory that doesn't exist on the server.",
    [10] = "FTP accept failed. While waiting for the server to connect back when an active FTP session is used, an error code was sent over the control connection or similar.",
    [11] = "FTP weird PASS reply. Curl couldn't parse the reply sent to the PASS request.",
    [12] = "During an active FTP session while waiting for the server to connect back to curl, the timeout expired.",
    [13] = "FTP weird PASV reply, Curl couldn't parse the reply sent to the PASV request.",
    [14] = "FTP weird 227 format. Curl couldn't parse the 227-line the server sent.",
    [15] = "FTP can't get host. Couldn't resolve the host IP we got in the 227-line.",
    [16] = "HTTP/2 error. A problem was detected in the HTTP2 framing layer. This is somewhat generic and can be one out of several problems, see the error message for details.",
    [17] = "FTP couldn't set binary. Couldn't change transfer method to binary.",
    [18] = "Partial file. Only a part of the file was transferred.",
    [19] = "FTP couldn't download/access the given file, the RETR (or similar) command failed.",
    [21] = "FTP quote error. A quote command returned error from the server.",
    [22] = "HTTP page not retrieved. The requested url was not found or returned another error with the HTTP error code being 400 or above. This return code only appears if -f, --fail is used.",
    [23] = "Write error. Curl couldn't write data to a local filesystem or similar.",
    [25] = "FTP couldn't STOR file. The server denied the STOR operation, used for FTP uploading.",
    [26] = "Read error. Various reading problems.",
    [27] = "Out of memory. A memory allocation request failed.",
    [28] = "Operation timeout. The specified time-out period was reached according to the conditions.",
    [30] = "FTP PORT failed. The PORT command failed. Not all FTP servers support the PORT command, try doing a transfer using PASV instead!",
    [31] = "FTP couldn't use REST. The REST command failed. This command is used for resumed FTP transfers.",
    [33] = 'HTTP range error. The range "command" didn\'t work.',
    [34] = "HTTP post error. Internal post-request generation error.",
    [35] = "SSL connect error. The SSL handshaking failed.",
    [36] = "Bad download resume. Couldn't continue an earlier aborted download.",
    [37] = "FILE couldn't read file. Failed to open the file. Permissions?",
    [38] = "LDAP cannot bind. LDAP bind operation failed.",
    [39] = "LDAP search failed.",
    [41] = "Function not found. A required LDAP function was not found.",
    [42] = "Aborted by callback. An application told curl to abort the operation.",
    [43] = "Internal error. A function was called with a bad parameter.",
    [45] = "Interface error. A specified outgoing interface could not be used.",
    [47] = "Too many redirects. When following redirects, curl hit the maximum amount.",
    [48] = "Unknown option specified to libcurl. This indicates that you passed a weird option to curl that was passed on to libcurl and rejected. Read up in the manual!",
    [49] = "Malformed telnet option.",
    [51] = "The peer's SSL certificate or SSH MD5 fingerprint was not OK.",
    [52] = "The server didn't reply anything, which here is considered an error.",
    [53] = "SSL crypto engine not found.",
    [54] = "Cannot set SSL crypto engine as default.",
    [55] = "Failed sending network data.",
    [56] = "Failure in receiving network data.",
    [58] = "Problem with the local certificate.",
    [59] = "Couldn't use specified SSL cipher.",
    [60] = "Peer certificate cannot be authenticated with known CA certificates.",
    [61] = "Unrecognized transfer encoding.",
    [62] = "Invalid LDAP URL.",
    [63] = "Maximum file size exceeded.",
    [64] = "Requested FTP SSL level failed.",
    [65] = "Sending the data requires a rewind that failed.",
    [66] = "Failed to initialize SSL Engine.",
    [67] = "The user name, password, or similar was not accepted and curl failed to log in.",
    [68] = "File not found on TFTP server.",
    [69] = "Permission problem on TFTP server.",
    [70] = "Out of disk space on TFTP server.",
    [71] = "Illegal TFTP operation.",
    [72] = "Unknown TFTP transfer ID.",
    [73] = "File already exists (TFTP).",
    [74] = "No such user (TFTP).",
    [75] = "Character conversion failed.",
    [76] = "Character conversion functions required.",
    [77] = "Problem with reading the SSL CA cert (path? access rights?).",
    [78] = "The resource referenced in the URL does not exist.",
    [79] = "An unspecified error occurred during the SSH session.",
    [80] = "Failed to shut down the SSL connection.",
    [82] = "Could not load CRL file, missing or wrong format (added in 7.19.0).",
    [83] = "Issuer check failed (added in 7.19.0).",
    [84] = "The FTP PRET command failed",
    [85] = "RTSP: mismatch of CSeq numbers",
    [86] = "RTSP: mismatch of Session Identifiers",
    [87] = "unable to parse FTP file list",
    [88] = "FTP chunk callback reported error",
    [89] = "No connection available, the session will be queued",
    [90] = "SSL public key does not matched pinned public key",
    [91] = "Invalid SSL certificate status.",
    [92] = "Stream error in HTTP/2 framing layer.",
  }

  if not curl_error_dictionary[code] then
    return "cURL error " .. tostring(code) .. ": Unknown curl error"
  end
  return "cURL error " .. tostring(code) .. ": " .. curl_error_dictionary[code]
end

---Get request statistics
---@param req table cURL request class
---@param statistics_tbl RestConfigResultStats Statistics table
---@return table
local function get_stats(req, statistics_tbl)
  local logger = _G._rest_nvim.logger

  local stats = {}

  local function get_stat(req_, stat_)
    local curl_info = curl["INFO_" .. stat_:upper()]
    if not curl_info then
      ---@diagnostic disable-next-line need-check-nil
      logger:error(
        "The cURL request stat field '"
          .. stat_("' was not found.\nPlease take a look at: https://curl.se/libcurl/c/curl_easy_getinfo.html")
      )
      return
    end
    local stat_info = req_:getinfo(curl_info)

    if stat_:find("size") then
      stat_info = utils.transform_size(stat_info)
    elseif stat_:find("time") then
      stat_info = utils.transform_time(stat_info)
    end
    return stat_info
  end

  local stat_key, stat_title, stat_info
  for _, stat in pairs(statistics_tbl) do
    for k, v in pairs(stat) do
      if type(k) == "string" and k == "title" then
        stat_title = v
      end
      if type(k) == "number" then
        stat_key = v
        stat_info = get_stat(req, v)
      end
    end
    stats[stat_key] = stat_title .. " " .. stat_info
  end

  return stats
end

---Execute an HTTP request using cURL
---@param request Request Request data to be passed to cURL
---@return table
function client.request(request)
  local logger = _G._rest_nvim.logger

  -- We have to concat request headers to a single string, e.g. ["Content-Type"]: "application/json" -> "Content-Type: application/json"
  local headers = {}
  for name, value in pairs(request.headers) do
    table.insert(headers, name .. ": " .. value)
  end

  -- Whether to skip SSL host and peer verification
  local skip_ssl_verification = _G._rest_nvim.skip_ssl_verification
  local req = curl.easy_init()
  req:setopt({
    url = request.request.url,
    -- verbose = true,
    httpheader = headers,
    ssl_verifyhost = skip_ssl_verification,
    ssl_verifypeer = skip_ssl_verification,
  })

  -- Set request HTTP version, defaults to HTTP/1.1
  if request.request.http_version then
    local http_version = request.request.http_version:gsub("%.", "_")
    req:setopt_http_version(curl["HTTP_VERSION_" .. http_version])
  else
    req:setopt_http_version(curl.HTTP_VERSION_1_1)
  end

  -- If the request method is not GET then we have to build the method in our own
  -- See: https://github.com/Lua-cURL/Lua-cURLv3/issues/156
  local method = request.request.method
  if vim.tbl_contains({ "POST", "PUT", "PATCH", "TRACE", "OPTIONS", "DELETE" }, method) then
    req:setopt_post(true)
    req:setopt_customrequest(method)
  end

  -- Request body
  if request.body.__TYPE == "json" then
    -- Create a copy of the request body table to remove the unneeded `__TYPE` metadata field
    local body = request.body
    body.__TYPE = nil

    local json_body_string = vim.json.encode(request.body)
    req:setopt_postfields(json_body_string)
  elseif request.body.__TYPE == "external_file" then
    local body_mimetype = mimetypes.guess(request.body.path)
    local post_data = {
      [request.body.name and request.body.name or "body"] = {
        file = request.body.path,
        type = body_mimetype,
      },
    }
    req:post(post_data)
  end

  -- Request execution
  local res_result = {}
  local res_headers = {}
  req:setopt_writefunction(table.insert, res_result)
  req:setopt_headerfunction(table.insert, res_headers)

  local ret = {}
  local ok, err = req:perform()
  if ok then
    -- Get request statistics if they are enabled
    local stats_config = _G._rest_nvim.result.behavior.statistics
    if stats_config.enable then
      ret.statistics = get_stats(req, stats_config.stats)
    end

    ret.url = req:getinfo_effective_url()
    ret.code = req:getinfo_response_code()
    ret.method = req:getinfo_effective_method()
    ret.headers = table.concat(res_headers):gsub("\r", "")
    ret.body = table.concat(res_result)

    if request.script ~= nil or not request.script == "" then
      script_vars.load(request.script, ret)
    end
  else
    ---@diagnostic disable-next-line need-check-nil
    logger:error("Something went wrong when making the request with cURL:\n" .. curl_error(err:no()))
    return {}
  end
  req:close()

  return ret
end

return client
