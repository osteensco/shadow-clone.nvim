local utils = require('shadow-clone.utils')
local _win = require('shadow-clone.window')
local manager = require('manager')


local split = {}

-- split floating window horizontally
split.h_split = function()
    -- if not vim.api.nvim_win_is_valid(win) then
    local win = vim.api.nvim_get_current_win()
    -- end

    if not utils.is_floating(win) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(win)
    local anchor = vim.api.nvim_win_get_position(win)
    local win_h = vim.api.nvim_win_get_height(win)
    local win_w = vim.api.nvim_win_get_width(win)

    local group = manager.peek()
    -- assert(next(group),
    --     "Peek should not return an empty table when a floating window exists.")
    if next(group) then
        manager.remove_from_group(group, { bufnr = buf, win = win })
    end
    vim.api.nvim_win_hide(win)

    _win.create_floating_window({
        buf = buf,
        win_config = {
            height = math.floor(win_h / 2) - 1,
            width = win_w,
            row = anchor[1],
            col = anchor[2]
        },
        newgroup = false
    })
    _win.create_floating_window({
        buf = buf,
        win_config = {
            height = math.floor(win_h / 2),
            width = win_w,
            row = anchor[1] + math.floor(win_h / 2) + 1,
            col = anchor[2]
        },
        newgroup = false
    })
end

-- split floating window vertically
split.v_split = function()
    -- if not vim.api.nvim_win_is_valid(win) then
    local win = vim.api.nvim_get_current_win()
    -- end

    if not utils.is_floating(win) then
        return
    end

    local buf = vim.api.nvim_win_get_buf(win)
    local anchor = vim.api.nvim_win_get_position(win)
    local win_h = vim.api.nvim_win_get_height(win)
    local win_w = vim.api.nvim_win_get_width(win)

    local group = manager.peek()
    -- assert(next(group),
    --     "Peek should not return an empty table when a floating window exists.")
    if next(group) then
        manager.remove_from_group(group, { bufnr = buf, win = win })
    end
    vim.api.nvim_win_hide(win)

    _win.create_floating_window({
        buf = buf,
        win_config = {
            height = win_h,
            width = math.floor(win_w / 2) - 1,
            row = anchor[1],
            col = anchor[2]
        },
        newgroup = false
    })
    _win.create_floating_window({
        buf = buf,
        win_config = {
            height = win_h,
            width = math.floor(win_w / 2),
            row = anchor[1],
            col = anchor[2] + math.floor(win_w / 2) + 1
        },
        newgroup = false
    })
end



return split
