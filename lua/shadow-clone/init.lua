local utils = require("utils")
local manager = require("manager")


local M = {}

-- defaults
M.config = {
    float_window = {
        position = 'center',
        -- TODO
        -- height/width % and minimums should be passed in
        width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10))),
        height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5))),
    },
    normal_window = {},
}



-- public methods

-- opts = {
--     win_config = {},
--     buf = -1
-- }
--
-- args:
--  - opts: optionally provide you're own win_config to be passed to vim.api.nvim_open_win,
--    and/or buffer to be reused.
M.create_floating_window = function(opts)
    opts = opts or {}

    opts.config = M.config.float_window

    local pos = utils.get_pos(opts.config.position, opts.config.width, opts.config.height)

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
    win_config = vim.tbl_deep_extend('force', win_config, opts.win_config)

    local buf = opts.buf or -1
    if vim.api.nvim_buf_is_valid(buf) then
        buf = buf
    else
        buf = vim.api.nvim_create_buf(false, true)
    end

    local window = {
        buf = buf,
        win = vim.api.nvim_open_win(buf, true, win_config)
    }

    manager.append(window)

    return window
end

-- toggle a floating terminal, creates a new terminal buffer if float.term.last_accessed is nil
M.toggle_floating_terminal = function()
    local term = manager.ledger.float.terminal.last_accessed
    if not vim.api.nvim_win_is_valid(term.win) then
        term = M.create_floating_window({ buf = term.buf })
        -- TODO
        --  - abstract into "terminal start" function
        if vim.bo[term.buf].buftype ~= "terminal" then
            vim.cmd.terminal()
        end
        manager.update_access(term)
    else
        vim.api.nvim_win_hide(term.win)
    end
end

-- move current buffer out into a floating window
M.move_to_floating_window = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local win_type = vim.fn.win_gettype(win)
    if win_type ~= "popup" then
        vim.api.nvim_win_close(win, true)
        M.create_floating_window({ buf = buf })
    end
end

-- hide current floating window
M.hide_floating_window = function()
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_hide(win)
end

-- toggle last accessed window
M.toggle_last_accessed_win = function()
    local win = manager.ledger.float.window.last_accessed
    if not vim.api.nvim_win_is_valid(win.win) then
        win = M.create_floating_window({ buf = win.buf })
    else
        M.hide_floating_window()
    end
end

-- split floating window horizontally
M.h_split = function()
    local win = vim.api.nvim_get_current_win()

    if not utils.is_floating(win) then
        return
    end

    -- grab buffer, height, and width
    local buf = vim.api.nvim_get_current_buf()
    local win_h = vim.api.nvim_win_get_height(win)
    local win_w = vim.api.nvim_win_get_width(win)

    local pos = utils.get_pos("center", win_w, win_h)

    -- close window, retain buffer
    vim.api.nvim_win_hide(win)

    -- open two windows using same buffer
    -- width is the same for both
    -- height of windows is original height minus some padding
    M.create_floating_window({ buf = buf, win_config = { height = math.floor(win_h / 2) - 2 } })
    M.create_floating_window({ buf = buf, win_config = { height = math.floor(win_h / 2) - 2, row = pos.y + math.floor(win_h / 2) + 4 } })
end

-- split floating window vertically
-- TODO
-- implement v_split
M.v_split = function()
    local win = vim.api.nvim_get_current_win()
    -- grab buffer, height, and width
    -- close window
    -- open two windows using same buffer
    -- height is the same for both
    -- width of windows is original height minus some padding
end









-- commands
vim.api.nvim_create_user_command("SCwindow", M.create_floating_window, { nargs = '?' })
vim.api.nvim_create_user_command("SCtoggleterm", M.toggle_floating_terminal, { nargs = 0 })
vim.api.nvim_create_user_command("SCpop", M.move_to_floating_window, { nargs = 0 })
vim.api.nvim_create_user_command("SChide", M.hide_floating_window, { nargs = 0 })
vim.api.nvim_create_user_command("SCtoggle", M.toggle_last_accessed_win, { nargs = 0 })
vim.api.nvim_create_user_command("SCsplit", M.h_split, { nargs = 0 })


-- setup function
M.setup = function(config)
    config = config or {}
    M.config = vim.tbl_deep_extend('force', M.config, config)
end

-- TODO REMOVE ME!!!!!
-- M.create_floating_window()
-- print(vim.inspect(M.manager.float[1]))


return M
