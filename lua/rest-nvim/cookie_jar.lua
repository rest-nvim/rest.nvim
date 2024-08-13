---@mod rest-nvim.cookie_jar Cookie handler module

local M = {
  ---@type rest.Cookie[]
  jar = {},
}

local utils = require("rest-nvim.utils")
local logger = require("rest-nvim.logger")
local config = require("rest-nvim.config")

---@class rest.Cookie
---@field name string
---@field value string
---@field domain string
---@field path string
---@field expires integer
---@field max_date integer?
---@field secure boolean?
---@field httponly boolean?
---@field samesite string?
---@field priority string?

---Load Cookie jar from rest-nvim.cookies file
function M.load_jar()
  if not utils.file_exists(config.cookies.path) then
    return
  end
  local file, openerr = io.open(config.cookies.path, "r")
  if not file then
    local err_msg = string.format("Failed to open rest.nvim cookies file: %s", openerr)
    vim.notify(err_msg, vim.log.levels.ERROR)
    logger.error(err_msg)
    return
  end
  for line in file:lines() do
    local seps = vim.split(line, "\t")
    if seps[1] ~= "" and not vim.startswith(seps[1], "#") then
      if #seps ~= 5 then
        local err_msg = "error while parsing cookies file at line:\n" .. line .. "\n"
        vim.notify("[rest.nvim] " .. err_msg, vim.log.levels.ERROR)
        logger.error(err_msg)
        return
      end
      ---@type rest.Cookie
      local cookie = {
        domain = seps[1],
        path = seps[2],
        name = seps[3],
        value = seps[4],
        expires = assert(tonumber(seps[5])),
      }
      table.insert(M.jar, cookie)
    end
  end
end

---parse url to domain and path
---path will be fallback to "/" if not found
---@param url string
---@return string domain
---@return string path
local function parse_url(url)
  local domain, path = url:match("^https?://([^/]+)(/[^?#]*)$")
  if not path then
    domain = url:match("^https?://([^/]+)")
    path = "/"
  end
  return domain, path
end

---@private
---parse Set-Cookie header to cookie
---@param req_url string request URL to be used as fallback domain & path of cookie
---@param header string
---@return rest.Cookie?
function M.parse_set_cookie(req_url, header)
  local name, value = header:match("^%s*([^=]+)=([^;]*)")
  if not name then
    logger.error("Invalid Set-Cookie header: " .. header)
    return
  end
  local cookie = {
    name = name,
    value = value or "",
  }
  for attr, val in header:gmatch(";%s*([^=]+)=?([^;]*)") do
    attr = attr:lower()
    if attr == "domain" then
      cookie.domain = val
    elseif attr == "path" then
      cookie.path = val
    elseif attr == "expires" then
      cookie.expires = utils.parse_http_time(val)
    elseif attr == "max-age" then
      cookie.max_age = tonumber(val)
    elseif attr == "secure" then
      cookie.secure = true
    elseif attr == "httponly" then
      cookie.httponly = true
    elseif attr == "samesite" then
      cookie.samesite = val
    elseif attr == "priority" then
      cookie.priority = val
    end
  end
  cookie.domain = cookie.domain or req_url:match("^https?://([^/]+)")
  cookie.domain = "." .. cookie.domain
  cookie.path = cookie.path or "/"
  cookie.expires = cookie.expires or -1
  return cookie
end

---@param jar rest.Cookie[]
---@param cookie rest.Cookie
local function jar_insert(jar, cookie)
  for i, c in ipairs(jar) do
    if c.name == cookie.name and c.domain == cookie.domain and c.path == cookie.path then
      jar[i] = cookie
      return
    end
  end
  table.insert(jar, cookie)
end

---@param fn function
---@param arg any
local function curry(fn, arg)
  return function(...)
    return fn(arg, ...)
  end
end

---Save cookies from response
---Request is provided as a context
---@param req_url string
---@param res rest.Response
function M.update_jar(req_url, res)
  if not res.headers["set-cookie"] then
    return
  end
  vim.iter(res.headers["set-cookie"]):map(curry(M.parse_set_cookie, req_url)):each(curry(jar_insert, M.jar))
  M.clean()
  M.save_jar()
end

---@private
---Cleanup expired cookies
function M.clean()
  M.jar = vim
    .iter(M.jar)
    :filter(function(cookie)
      return cookie.max_age == 0 or cookie.expires < os.time()
    end)
    :totable()
end

---Save current cookie jar to cookies file
function M.save_jar()
  -- TOOD: make this function asynchronous
  local file, openerr = io.open(config.cookies.path, "w")
  if not file then
    local err_msg = string.format("Failed to open rest.nvim cookies file: %s", openerr)
    vim.notify("[rest.nvim] " ..err_msg, vim.log.levels.ERROR)
    logger.error(err_msg)
    return
  end
  file:write("# domain\tpath\tname\tvalue\texpires\n")
  for _, cookie in ipairs(M.jar) do
    file:write(table.concat({
      cookie.domain,
      cookie.path,
      cookie.name,
      cookie.value,
      cookie.expires,
    }, "\t") .. "\n")
  end
  file:close()
end

local function match_cookie(url, cookie)
  local req_domain, req_path = parse_url(url)
  if not req_domain then
    return false
  end
  local domain_matches = ("." .. req_domain):match(vim.pesc(cookie.domain) .. "$")
  local path_matches = req_path:sub(1, #cookie.path) == cookie.path
  if domain_matches and path_matches then
    logger.debug(
      ("cookie %s with domain %s and path %s matched to url: %s"):format(cookie.name, cookie.domain, cookie.path, url)
    )
  else
    logger.debug(
      ("cookie %s with domain %s and path %s NOT matched to url: %s"):format(
        cookie.name,
        cookie.domain,
        cookie.path,
        url
      )
    )
  end
  return domain_matches and path_matches
end

---Load cookies for request
---@param req rest.Request
function M.load_cookies(req)
  logger.debug("loading cookies for request:" .. req.url)
  vim.iter(M.jar):filter(curry(match_cookie, req.url)):each(curry(jar_insert, req.cookies))
end

M.load_jar()

return M
