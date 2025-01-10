local manager = require('manager')
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

    ---@type WinObj
    local window = {
        bufnr = buf,
        win = winnr,
        anchor = vim.api.nvim_win_get_position(winnr)
    }

    ---@type WinGroup
    local group = manager.new_group()
    if not opts.newgroup then
        local g = manager.pop()
        group = g or group
    end
    manager.add_to_group(group, window)
    manager.push(group, window)

    ---show additional info if in debug mode
    local grp = manager.peek()
    utils.debug_display(grp, window)

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




-- TODO
--  - use these to implement hide and toggle
-- manager.hide_top_group
-- manager.toggle_last_accessed_group





return win
