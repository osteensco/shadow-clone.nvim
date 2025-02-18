local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local manager = require("scmanager")
local window = require("shadow-clone.window")



local pick = {}



local function unhide_group(selected_group)
    -- TODO
    --  - fix this
    --  - this should only need window.unhide_group, manager calls should be in this function

    local max_zindex = 0
    for _, group in ipairs(manager.list_hidden()) do
        if group.zindex > max_zindex then
            max_zindex = group.zindex
        end
    end

    selected_group.zindex = max_zindex + 1
    print("Unhid WinGroup :", selected_group.zindex)
end

local function generate_preview_contents(group)
    if not group or not group.members then return "No windows in this group" end

    local lines = {}
    for i, win in ipairs(group.members) do
        -- TODO
        --  - figure out if adding highlighting within each window in the preview is possible
        table.insert(lines,
            string.format("Win %d:\nFile: %s \n| Buf: %d | Anchor: (%d, %d) | Size: %dx%d |", i,
                vim.api.nvim_buf_get_name(win.bufnr),
                win.bufnr, win.anchor[1], win.anchor[2], win.width, win
                .height))
        table.insert(lines,
            "____________________________________________________________________________________________________")
        local cursor_pos = vim.api.nvim_buf_get_mark(win.bufnr, '"')
        table.insert(lines,
            table.concat(vim.api.nvim_buf_get_lines(win.bufnr, cursor_pos[1], cursor_pos[1] + 9, false), "\n"))
        table.insert(lines,
            "____________________________________________________________________________________________________")
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
            end,
        }),
        attach_mappings = function(prompt_bufnr, map)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                if selection then
                    actions.close(prompt_bufnr)
                    unhide_group(selection.value)
                end
            end)
            return true
        end,
        default_selection_index = #hidden_groups,
    }):find()
end



pick.hidden_windows()
-- return pick
