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
    opts.buf = opts.buf or -1
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

    -- create buffer if one is not provided or provided one is invalid
    local buf = opts.buf
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

    local grp = manager.peek()
    local testconfig = {
        title = "group: " ..
            grp.zindex .. " win: " .. window.win .. " - x: " .. window.anchor[2] .. ", y: " .. window.anchor[1],
        title_pos = "center"
    }
    vim.api.nvim_win_set_config(window.win, testconfig)
    return window
end


return win
