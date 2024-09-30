local telescope = require("telescope")

local state = require("telescope.actions.state")
local action_state = require("telescope.actions.state")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local make_entry = require("telescope.make_entry")

local function rest_env_select(_)
    local dotenv = require("rest-nvim.dotenv")

    local lines = dotenv.find_env_files()

    local opts = {}
    opts.entry_maker = make_entry.gen_from_file(opts)

    pickers
        .new(opts, {
            prompt_title = "Select Env File",
            finder = finders.new_table({
                results = lines,
                entry_maker = make_entry.gen_from_file(),
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
                    local selection = state.get_selected_entry()
                    if selection == nil then
                        return
                    end
                    vim.cmd.edit(selection[1])
                end)
                return true
            end,
            previewer = conf.file_previewer(opts),
            sorter = conf.file_sorter(opts),
        })
        :find()
end

return telescope.register_extension({
    exports = {
        select_env = rest_env_select,
    },
})
