local rest = require("rest-nvim")

describe("rest testing framework", function()
  it("test create users", function()
    local opts = { keep_going = true, verbose = true }
    assert(rest.run_file("tests/basic_get.http", opts) == true)
    assert(rest.run_file("tests/post_json_form.http", opts) == true)
    assert(rest.run_file("tests/post_create_user.http", opts) == true)
    assert(rest.run_file("tests/put_update_user.http", opts) == true)
    assert(rest.run_file("tests/patch_update_user.http", opts) == true)
    assert(rest.run_file("tests/delete.http", opts) == true)
  end)
end)
