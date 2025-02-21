local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local manager = require("scmanager")
local window = require("shadow-clone.window")



local pick = {}



local function generate_preview_contents(group)
    if not group or not group.members then return "No windows in this group" end

    local lines = {}
    for i, win in ipairs(group.members) do
        local cursor_pos = vim.api.nvim_buf_get_mark(win.bufnr, '"')
        local start_line, end_line = cursor_pos[1], cursor_pos[1] + 9
        local filepath = vim.api.nvim_buf_get_name(win.bufnr)
        local filetype = vim.bo[win.bufnr].filetype

        table.insert(lines,
            string.format("File: %s \n| Buf: %d | Anchor: (%d, %d) | Size: %dx%d |",
                filepath,
                win.bufnr, win.anchor[1], win.anchor[2], win.width, win
                .height))
        table.insert(lines,
            "____________________________________________________________________________________________________")

        table.insert(lines, string.format("```" .. filetype))
        table.insert(lines,
            table.concat(vim.api.nvim_buf_get_lines(win.bufnr, start_line, end_line, false), "\n"))
        table.insert(lines, "```")


        table.insert(lines,
            "____________________________________________________________________________________________________\n")
    end

    return table.concat(lines, "\n")
end





pick.hidden_windows = function(opts)
    opts = opts or {}
    local hidden_groups = manager.list_hidden()

    if #hidden_groups == 0 then
        print("No groups in the hidden stack.")
        return
    end

    for i, grp in ipairs(hidden_groups) do
        grp.pos = i
    end

    pickers.new({}, {
        prompt_title = "Select Hidden Group",
        finder = finders.new_table({
            results = hidden_groups,
            entry_maker = function(group)
                local display_filenames = ""
                for _, win in ipairs(group.members) do
                    local filename = vim.api.nvim_buf_get_name(win.bufnr)
                    display_filenames = display_filenames .. " | " .. filename
                end

                local entry = string.format("%d", group.pos) .. display_filenames


                return {
                    value = group,
                    display = entry,
                    ordinal = entry,
                }
            end,
        }),
        sorter = conf.generic_sorter(),
        previewer = previewers.new_buffer_previewer({
            title = "Hidden Group Preview",
            define_preview = function(self, entry, status)
                local preview_text = generate_preview_contents(entry.value)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, vim.split(preview_text, "\n"))
                vim.bo[self.state.bufnr].filetype = "markdown"

                vim.api.nvim_set_option_value('conceallevel', 2, { win = self.state.winid })
            end,
        }),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                    window.unhide_group(selection.value)
                end
            end)
            return true
        end,
        default_selection_index = #hidden_groups,
    }):find()
end



-- pick.hidden_windows()
return pick
