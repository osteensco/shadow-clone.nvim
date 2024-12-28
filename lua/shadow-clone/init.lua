local utils = require("utils")
local manager = require("manager")


local M = {}

-- defaults

---@class FloatConfig Float window settings.
---@field position string String representing how the window is anchored (center, left, right, top, bottom).
---@field width number
---@field height number

---@class Config Settings passed to setup function that shadow-clone.nvim uses.
---@field float_window? FloatConfig
M.config = {
    float_window = {
        position = 'center',
        -- TODO
        -- height/width % and minimums should be passed in
        width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10))),
        height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5))),
    },
}



-- public methods

---@class CreateFloatOpts
---@field win_config? vim.api.keyset.win_config
---@field config? FloatConfig
---@field buf? number
---@field newgroup boolean

--- Creates a floating window and adds it to shadow-clone.nvim's window manager.
--- Uses a default config if none is passed in, and creates a new buffer if an existing one is not provided.
---@param opts? CreateFloatOpts Optionally provide you're own win_config to be passed to vim.api.nvim_open_win, and/or buffer to be reused. For win_config see `vim.api.keyset.win_config`.
---@return WinObj
M.create_floating_window = function(opts)
    opts = opts or {}
    opts.win_config = opts.win_config or {}

    -- set defaults
    opts.config = M.config.float_window

    local pos = utils.get_pos(opts.config.position, -1, opts.config.width, opts.config.height)

    local win_config = {
        relative = "editor",
        width = opts.config.width,
        height = opts.config.height,
        col = pos.x,
        row = pos.y,
        style = "minimal",
        border = "rounded",
        -- TODO
        -- need highlight group for background
    }

    -- override defaults with provided opts
    win_config = vim.tbl_deep_extend('force', win_config, opts.win_config)

    -- create buffer if one is not provided or provided one is invalid
    local buf = opts.buf or -1
    if vim.api.nvim_buf_is_valid(buf) then
        buf = buf
    else
        buf = vim.api.nvim_create_buf(false, true)
    end

    -- window obj
    local window = {
        bufnr = buf,
        win = vim.api.nvim_open_win(buf, true, win_config)
    }

    -- add window to shadow-clone.nvim's manager
    local group = {}
    if not opts.newgroup then
        group = manager.pop()
    end
    manager.add_to_group(group, window)
    manager.push(group)

    return window
end

-- toggle a floating terminal, creates a new terminal buffer if float.term.last_accessed is nil
-- M.toggle_floating_terminal = function()
--     local term = manager.ledger.float.terminal.last_accessed
--     if not vim.api.nvim_win_is_valid(term.win) then
--         term = M.create_floating_window({ buf = term.buf })
--         -- TODO
--         --  - abstract into "terminal start" function
--         if vim.bo[term.buf].buftype ~= "terminal" then
--             vim.cmd.terminal()
--         end
--         manager.update_access(term)
--     else
--         vim.api.nvim_win_hide(term.win)
--     end
-- end

-- move current buffer into a new floating window (normal -> floating)
M.bubble_up = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local win_type = vim.fn.win_gettype(win)
    if win_type ~= "popup" then
        vim.api.nvim_win_close(win, true)
        M.create_floating_window({ buf = buf, newgroup = true })
    end
end

-- move current buffer into the last accessed normal window (floating -> normal)
M.bubble_down = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local win_type = vim.fn.win_gettype(win)
    if win_type == "popup" then
        vim.api.nvim_win_close(win, true)
        local group = manager.peak()
        manager.remove_from_group(group, { bufnr = buf, win = win })
        vim.api.nvim_set_current_buf(buf)
    end
end

-- move current buffer into a horizontal split of the last accessed normal window (floating -> normal)
M.bubble_down_h = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local win_type = vim.fn.win_gettype(win)
    if win_type == "popup" then
        vim.api.nvim_win_close(win, true)
        local group = manager.peak()
        manager.remove_from_group(group, { bufnr = buf, win = win })
        vim.cmd("split")
        vim.api.nvim_set_current_buf(buf)
    end
end

-- move current buffer into a vertical split of the last accessed normal window (floating -> normal)
M.bubble_down_v = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local win_type = vim.fn.win_gettype(win)
    if win_type == "popup" then
        vim.api.nvim_win_close(win, true)
        local group = manager.peak()
        manager.remove_from_group(group, { bufnr = buf, win = win })
        vim.cmd("vsplit")
        vim.api.nvim_set_current_buf(buf)
    end
end

--TODO
-- - rework hide and toggle functions
-- - how to handle hidden buffers (hidden stack?)

-- hide current floating window
-- M.hide_floating_window = function()
--     local win = vim.api.nvim_get_current_win()
--     vim.api.nvim_win_hide(win)
-- end
--
-- -- toggle last accessed window
-- M.toggle_last_accessed_win = function()
--     local win = manager.ledger.float.window.last_accessed
--     if not vim.api.nvim_win_is_valid(win.win) then
--         win = M.create_floating_window({ buf = win.buf })
--     else
--         M.hide_floating_window()
--     end
-- end

-- split floating window horizontally
M.h_split = function()
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

    vim.api.nvim_win_hide(win)

    M.create_floating_window({
        buf = buf,
        win_config = {
            height = math.floor(win_h / 2) - 1,
            width = win_w,
            row = anchor[1],
            col = anchor[2]
        },
        newgroup = false
    })
    M.create_floating_window({
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
M.v_split = function()
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

    vim.api.nvim_win_hide(win)

    M.create_floating_window({
        buf = buf,
        win_config = {
            height = win_h,
            width = math.floor(win_w / 2) - 1,
            row = anchor[1],
            col = anchor[2]
        },
        newgroup = false
    })
    M.create_floating_window({
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









-- commands
vim.api.nvim_create_user_command("SCwindow", M.create_floating_window, { nargs = '?' })
-- vim.api.nvim_create_user_command("SCtoggleterm", M.toggle_floating_terminal, { nargs = 0 })
vim.api.nvim_create_user_command("SCbubbleup", M.bubble_up, { nargs = 0 })
vim.api.nvim_create_user_command("SCbubbledown", M.bubble_down, { nargs = 0 })
vim.api.nvim_create_user_command("SCbubbledownh", M.bubble_down_h, { nargs = 0 })
vim.api.nvim_create_user_command("SCbubbledownv", M.bubble_down_v, { nargs = 0 })
-- vim.api.nvim_create_user_command("SChide", M.hide_floating_window, { nargs = 0 })
-- vim.api.nvim_create_user_command("SCtoggle", M.toggle_last_accessed_win, { nargs = 0 })
vim.api.nvim_create_user_command("SCsplit", M.h_split, { nargs = '?' })
vim.api.nvim_create_user_command("SCvsplit", M.v_split, { nargs = '?' })



-- setup function
---@param config Config
M.setup = function(config)
    config = config or {}
    M.config = vim.tbl_deep_extend('force', M.config, config)
end




return M
