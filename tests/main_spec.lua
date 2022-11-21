local rest = require('rest-nvim')
local v = vim

describe("rest testing framework", function()

    it('test create users', function()

      v.api.nvim_cmd({cmd='edit', args =  {'tests/post_create_user.http'}}, {})

      -- first argument is for verbosity
      rest.run(false)
    end)
end)
