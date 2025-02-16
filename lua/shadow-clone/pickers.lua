local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local manager = require("scmanager")
local window = require("shadow-clone.window")

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
    print("Unhid WinGroup at highest zindex:", selected_group.zindex)
end

local function generate_window_preview(group)
    if not group or not group.members then return "No windows in this group" end

    local lines = { "Window Layout Preview:", string.format("Z-Index: %d", group.zindex), "" }
    for _, win in ipairs(group.members) do
        -- TODO
        --  - show buffers filepath
        --  - show preview of buffer if possible
        table.insert(lines,
            string.format("Buf: %d | Pos: (%d, %d) | %dx%d", win.bufnr, win.anchor[1], win.anchor[2], win.width, win
                .height))
    end

    return table.concat(lines, "\n")
end

local function pick_hidden_windows()
    local hidden_groups = manager.list_hidden()

    if #hidden_groups == 0 then
        print("No hidden windows to show.")
        return
    end

    pickers.new({}, {
        prompt_title = "Select Hidden Windows",
        finder = finders.new_table({
            results = hidden_groups,
            entry_maker = function(group)
                return {
                    value = group,
                    display = string.format("Group: %d windows, %s", #group.members, vim.inspect(group.members)),
                    ordinal = tostring(group.zindex),
                }
            end,
        }),
        sorter = conf.generic_sorter({}),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, status)
                local preview_text = generate_window_preview(entry.value)
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
    }):find()
end

pick_hidden_windows()
