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
    local pos = utils.get_pos(config.float_window.position, -1, config.float_window.width, config.float_window.height)
    local win_config = {
        relative = "editor",
        width = config.float_window.width,
        height = config.float_window.height,
        col = pos.x,
        row = pos.y,
        style = "minimal",
        border = "rounded",
        -- TODO
        -- need highlight group for background
    }

    -- override defaults with provided opts
    win_config = vim.tbl_deep_extend('force', win_config, opts.win_config)

    -- establish buffer
    if vim.api.nvim_buf_is_valid(buf) then
        buf = buf
    else
        buf = vim.api.nvim_create_buf(false, true)
    end

    local winnr = vim.api.nvim_open_win(buf, true, win_config)



    -- TODO
    --  - break out logic that updates manager's stack into speparate function
    --  - add custom window variable: vim.w[winnr].sc = true

    ---@type WinObj
    local window = {
        bufnr = buf,
        win = winnr,
        anchor = vim.api.nvim_win_get_position(winnr),
        height = win_config.height,
        width = win_config.width,
    }

    ---@type WinGroup
    local group = manager.new_group()
    if not opts.newgroup then
        local g = manager.pop()
        group = g or group
    end
    manager.add_to_group(group, window)
    manager.push(group)

    ---show additional info if in debug mode
    local grp = manager.peek()
    utils.debug_display(grp, window)

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
    for _, w in ipairs(group.members) do
        win.create_floating_window({
            buf = w.bufnr,
            win_config = {
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
