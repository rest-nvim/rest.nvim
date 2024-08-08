---@module 'luassert'

require("spec.minimum_init")

local Context = require("rest-nvim.context").Context
local curl = require("rest-nvim.client.curl.cli")
local builder = curl.builder
local parser = curl.parser
local nio = require("nio")

describe("curl cli builder", function()
  it("from GET request", function()
    local args = builder.build({
      context = Context:new(),
      method = "GET",
      url = "http://localhost:8000",
      headers = {},
      handlers = {},
    })
    assert.same({ "http://localhost:8000", "-X", "GET" }, args)
  end)
  it("from POST request with form body", function ()
    local args = builder.build({
      context = Context:new(),
      method = "POST",
      url = "http://localhost:8000",
      headers = {},
      handlers = {},
      body = {
        __TYPE = "form",
        data = {
          foo = "bar",
        },
      },
    })
    assert.same({ "http://localhost:8000", "-X", "POST", "-F", "foo=bar" }, args)
  end)
  it("from POST request with json body", function ()
    local json_text = [[{ "string": "foo", "number": 100, "array":  [1, 2, 3], "json": { "key": "value" } }]]
    local args = builder.build({
      context = Context:new(),
      method = "POST",
      url = "http://localhost:8000",
      headers = {
      },
      handlers = {},
      body = {
        __TYPE = "json",
        data = json_text,
      },
    })
    assert.same({ "http://localhost:8000", "-X", "POST", "--data-raw", json_text }, args)
  end)
  it("from POST request with external body", function ()
    local args = builder.build({
      context = Context:new(),
      method = "POST",
      url = "http://localhost:8000",
      headers = {
      },
      handlers = {},
      body = {
        __TYPE = "external",
        data = {
          path = "spec/test_server/post_json.json"
        },
      },
    })
    assert.same({ "http://localhost:8000", "-X", "POST", "--data-binary", "@spec/test_server/post_json.json" }, args)
  end)
end)

describe("curl cli response parser", function()
  it("from http GET request", function()
    local stdin = {
      "12:22:44.464640 *   Trying 127.0.0.1:8000...",
      "12:22:44.465279 * Connected to localhost (127.0.0.1) port 8000 (#0)",
      "12:22:44.466737 > GET / HTTP/1.1",
      "12:22:44.466737 > Host: localhost:8000",
      "12:22:44.466737 > User-Agent: curl/7.81.0",
      "12:22:44.466737 > Accept: */*",
      "12:22:44.466737 >",
      "12:22:44.480908 * Mark bundle as not supporting multiuse",
      "12:22:44.481033 < HTTP/1.1 200 OK",
      "12:22:44.481061 < Content-Type: text/plain",
      "12:22:44.481087 < Date: Tue, 06 Aug 2024 12:22:44 GMT",
      "12:22:44.481112 < Content-Length: 15",
      "12:22:44.481158 <",
      "12:22:44.481186 { [15 bytes data]",
      "12:22:44.481468 * Connection #0 to host localhost left intact",
    }
    local response = parser.parse_verbose(stdin)
    assert.same({
      status = {
        version = "HTTP/1.1",
        code = 200,
      },
      headers = {
        ["content-type"] = "text/plain",
        date = "Tue, 06 Aug 2024 12:22:44 GMT",
        ["content-length"] = "15",
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
