---@diagnostic disable: invisible
---@module 'luassert'

require("spec.minimum_init")

local Context = require("rest-nvim.context").Context
local curl = require("rest-nvim.client.curl.cli")
local builder = curl.builder
local parser = curl.parser
local nio = require("nio")

local STAT_FORMAT = builder.STAT_ARGS[2]

describe("curl cli builder", function()
  it("from GET request", function()
    local args = builder.build({
      context = Context:new(),
      method = "GET",
      url = "http://localhost:8000",
      headers = {},
      cookies = {},
      handlers = {},
    })
    assert.same({ "http://localhost:8000", "-X", "GET", "-w", STAT_FORMAT }, args)
  end)
  it("from GET request with headers", function()
    local args = builder.build({
      context = Context:new(),
      method = "GET",
      url = "http://localhost:8000",
      headers = {
        ["x-foo"] = { "bar" },
      },
      cookies = {},
      handlers = {},
    })
    assert.same({ "http://localhost:8000", "-X", "GET", "-H", "X-Foo: bar", "-w", STAT_FORMAT }, args)
  end)
  it("from POST request with form body", function ()
    local args = builder.build({
      context = Context:new(),
      method = "POST",
      url = "http://localhost:8000",
      headers = {},
      cookies = {},
      handlers = {},
      body = {
        __TYPE = "form",
        data = {
          foo = "bar",
        },
      },
    })
    assert.same({ "http://localhost:8000", "-X", "POST", "-F", "foo=bar", "-w", STAT_FORMAT }, args)
  end)
  it("from POST request with json body", function ()
    local json_text = [[{ "string": "foo", "number": 100, "array":  [1, 2, 3], "json": { "key": "value" } }]]
    local args = builder.build({
      context = Context:new(),
      method = "POST",
      url = "http://localhost:8000",
      headers = {},
      cookies = {},
      handlers = {},
      body = {
        __TYPE = "json",
        data = json_text,
      },
    })
    assert.same({ "http://localhost:8000", "-X", "POST", "--data-raw", json_text, "-w", STAT_FORMAT }, args)
  end)
  it("from POST request with external body", function ()
    local args = builder.build({
      context = Context:new(),
      method = "POST",
      url = "http://localhost:8000",
      headers = {},
      cookies = {},
      handlers = {},
      body = {
        __TYPE = "external",
        data = {
          path = "spec/test_server/post_json.json"
        },
      },
    })
    assert.same(
      { "http://localhost:8000", "-X", "POST", "--data-binary", "@spec/test_server/post_json.json", "-w", STAT_FORMAT },
      args
    )
  end)
end)

describe("curl cli response parser", function()
  it("from http GET request", function()
    local stdin = {
      "*   Trying 127.0.0.1:8000...",
      "* Connected to localhost (127.0.0.1) port 8000 (#0)",
      "> GET / HTTP/1.1",
      "> Host: localhost:8000",
      "> User-Agent: curl/7.81.0",
      "> Accept: */*",
      ">",
      "* Mark bundle as not supporting multiuse",
      "< HTTP/1.1 200 OK",
      "< Content-Type: text/plain",
      "< Date: Tue, 06 Aug 2024 12:22:44 GMT",
      "< Content-Length: 15",
      "<",
      "{ [15 bytes data]",
      "* Connection #0 to host localhost left intact",
    }
    local response = parser.parse_verbose(stdin)
    assert.same({
      status = {
        version = "HTTP/1.1",
        code = 200,
      },
      statistics = {},
      headers = {
        ["content-type"] = { "text/plain" },
        date = { "Tue, 06 Aug 2024 12:22:44 GMT" },
        ["content-length"] = { "15" },
      },
    }, response)
  end)
end)
describe("curl cli request", function()
  nio.tests.it("basic GET request", function()
    local response = curl
      .request({
        context = Context:new(),
        url = "https://reqres.in/api/users?page=5",
        handlers = {},
        headers = {},
        cookies = {},
        method = "GET",
      })
      .wait()
    assert.same(
      '{"page":5,"per_page":6,"total":12,"total_pages":2,"data":[],"support":{"url":"https://reqres.in/#support-heading","text":"To keep ReqRes free, contributions towards server costs are appreciated!"}}',
      response.body
    )
    assert.same({
        version = "HTTP/2",
        code = 200,
    }, response.status)
    -- HACK: have no idea how to make sure it is table<string,string>
    assert.are_table(response.headers)
  end)
end)
