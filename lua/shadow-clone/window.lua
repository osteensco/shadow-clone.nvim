local manager = require('scmanager')
local config = require('shadow-clone.config')
local utils = require('shadow-clone.utils')



local win = {}



---@class CreateFloatOpts
---@field buf? integer
---@field newgroup? boolean
---@field win_config? vim.api.keyset.win_config

--- Creates a floating window and adds it to shadow-clone.nvim's window manager.
--- Uses a default config if none is passed in, and creates a new buffer if an existing one is not provided.
---@param opts? CreateFloatOpts Optionally provide you're own win_config to be passed to vim.api.nvim_open_win, and/or buffer to be reused. For win_config see `vim.api.keyset.win_config`.
---@return WinObj
win.create_floating_window = function(opts)
    opts = opts or {}
    local buf = opts.buf or -1
    opts.win_config = opts.win_config or {}

    -- override defaults with provided opts
    local win_config = vim.tbl_deep_extend('force', config.win_config, opts.win_config)

    -- establish buffer
    if vim.api.nvim_buf_is_valid(buf) then
        buf = buf
    else
        buf = vim.api.nvim_create_buf(false, true)
    end

    local winnr = vim.api.nvim_open_win(buf, true, win_config)

    -- id window as created by shadow-clone to avoid duplicate stack update via event listener
    vim.api.nvim_win_set_var(winnr, "sc", true)

    -- We cannot rely on the event listener to update the manager's stack when this function is called
    -- because the split functionality has no way of knowing to populate the recently emptied group unless
    -- we explicitly pass in the new_group argument for the manifest_window method. Not doing it this way would
    -- create a new group every time any split function was called. Thus, the manifest_window method is necessary to call in this function.
    local window = manager.manifest_window(buf, winnr, win_config, opts.newgroup, config.DEBUG)

    return window
end


---Deconstruct a group's windows.
---@param group WinGroup
local decon_group = function(group)
    for _, w in ipairs(group.members) do
        vim.api.nvim_win_hide(w.win)
    end
end

---Reconstruct a group's windows from a WinGroup object.
---@param group WinGroup
local recon_group = function(group)
    -- init a temporary cache
    local cache = {}
    -- window needs to be removed from group so that the updated WinObj can be properly added back in
    -- the window id is -1 while hidden, when a window is created this id is updated and so the entire object needs to be flushed and readded
    for _, w in ipairs(group.members) do
        manager.remove_from_group(group, w)
        table.insert(cache, w)
    end
    -- creating a floating window will repopulate our group in the stack via manifest_window
    for _, w in ipairs(cache) do
        win.create_floating_window({
            buf = w.bufnr,
            win_config = {
                win = w.win,
                height = w.height,
                width = w.width,
                row = w.anchor[1],
                col = w.anchor[2]
            },
            newgroup = false,
        })
    end
end

-- Move the current group to a hidden state.
win.hide_group = function()
    local group = manager.peek()
    if group == {} then
        return
    end
    decon_group(group)
    manager.hide_top_group()
end

---Unhide a provided group
---@param group WinGroup
win.unhide_group = function(group)
    assert(group.members,
        "Group being moved to main stack should have at least two fields (id, members), got - " .. vim.inspect(group))
    assert(group.id,
        "Group being moved to main stack should have at least two fields (id, members), got - " .. vim.inspect(group))
    manager.unhide_group(group)
    recon_group(group)
end

---Unhide top group, places group top of main stack
win.unhide_top = function()
    local group = manager.hidden_peek()
    if group ~= {} then
        win.unhide_group(group)
    end
end

-- Open the group currently in the toggle slot or move the group from the top of the stack to the toggle slot.
win.toggle_group = function()
    local group, toggle_occupied = manager.toggle_last_accessed_group()
    if toggle_occupied then
        recon_group(group)
    else
        decon_group(group)
    end
end

-- Toggle the group persisted in the provided toggle buffer.
win.toggle_persisted_group = function(bufnr)
    local group, hidden = manager.toggle_persisted_group(bufnr)
    -- if found in a hidden state we need to reconstruct the windows
    if hidden then
        recon_group(group)
    else
        decon_group(group)
    end
end

-- Allocate a toggle buffer to a given group.
win.toggle_assign_buffer = function(group, bufnr)
    manager.set_toggle_buffer(group, bufnr)
end

---@return WinGroup
win.get_top_group = function()
    return manager.peek()
end





return win
