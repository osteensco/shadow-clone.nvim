local manager = require('manager')
local utils = require('shadow-clone.utils')
local _win = require('shadow-clone.window')

local nav = {}


-- move current buffer into a new floating window (normal -> floating)
nav.bubble_up = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local count = vim.fn.winnr('$')
    if not utils.is_floating(win) and count > 1 then
        vim.api.nvim_win_close(win, true)
        _win.create_floating_window({ buf = buf, newgroup = true })
    end
end

-- move current buffer into the last accessed normal window (floating -> normal)
nav.bubble_down = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local anchor = vim.api.nvim_win_get_position(win)
        local group = manager.peek()
        assert(#group == 0,
            "Expected WinGroup{members, zindex} got " .. vim.inspect(group) .. "length: " .. manager.get_len())
        manager.remove_from_group(group, { bufnr = buf, win = win, anchor = { x = anchor[1], y = anchor[2] } })
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_set_current_buf(buf)
    end
end

-- move current buffer into a horizontal split of the last accessed normal window (floating -> normal)
nav.bubble_down_h = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local anchor = vim.api.nvim_win_get_position(win)
        vim.api.nvim_win_close(win, true)
        local group = manager.peek()
        manager.remove_from_group(group, { bufnr = buf, win = win, anchor = { x = anchor[1], y = anchor[2] } })
        vim.cmd("split")
        vim.api.nvim_set_current_buf(buf)
    end
end

-- move current buffer into a vertical split of the last accessed normal window (floating -> normal)
nav.bubble_down_v = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local anchor = vim.api.nvim_win_get_position(win)
        vim.api.nvim_win_close(win, true)
        local group = manager.peek()
        manager.remove_from_group(group, { bufnr = buf, win = win, anchor = { x = anchor[1], y = anchor[2] } })
        vim.cmd("vsplit")
        vim.api.nvim_set_current_buf(buf)
    end
end

-- Move to the closest left window in the same group.
-- Moves to the rightmost if current window is the leftmost of the group.
nav.move_left = function()
    local group = manager.peek
end


return nav
