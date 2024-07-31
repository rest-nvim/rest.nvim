local has_telescope, telescope = pcall(require, "telescope")

if not has_telescope then
  return
end

local dotenv = require("rest-nvim.dotenv")

local state = require("telescope.actions.state")

local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values

local function rest_env_select(_)
  local pattern = _G._rest_nvim.env_pattern
  local edit = _G._rest_nvim.env_edit_command

  -- TODO: use dotenv.find_env_files instead
  local command = string.format("fd -HI '%s'", pattern)
  local result = io.popen(command):read("*a")

  local lines = {}
  for line in result:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end

  pickers
    .new({}, {
      prompt_title = "Select Env File",
      finder = finders.new_table({
        results = lines,
      }),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if selection == nil then
            return
          end
          dotenv.register_file(selection[1])
        end)
        map("i", "<c-o>", function()
          actions.close(prompt_bufnr)
          local selection = state.get_selected_entry(prompt_bufnr)
          if selection == nil then
            return
          end
          vim.api.nvim_command(edit .. " " .. selection[1])
        end)
        return true
      end,
      previewer = conf.grep_previewer({}),
    })
    :find()
end

return telescope.register_extension({
  exports = {
    select_env = rest_env_select,
  },
})
