local manager = require('manager')
local config = require('shadow-clone.config')
local utils = require('shadow-clone.utils')



local win = {}


---@class CreateFloatOpts
---@field win_config? vim.api.keyset.win_config
---@field config? FloatConfig
---@field buf? number
---@field newgroup boolean

--- Creates a floating window and adds it to shadow-clone.nvim's window manager.
--- Uses a default config if none is passed in, and creates a new buffer if an existing one is not provided.
---@param opts? CreateFloatOpts Optionally provide you're own win_config to be passed to vim.api.nvim_open_win, and/or buffer to be reused. For win_config see `vim.api.keyset.win_config`.
---@return WinObj
win.create_floating_window = function(opts)
    opts = opts or {}
    opts.win_config = opts.win_config or {}

    -- set defaults
    opts.config = config.float_window

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

    local winnr = vim.api.nvim_open_win(buf, true, win_config)

    -- window obj
    ---@class WinObj
    local window = {
        bufnr = buf,
        win = winnr,
        anchor = vim.api.nvim_win_get_position(winnr)
    }

    -- add window to shadow-clone.nvim's manager
    ---@class WinGroup
    local group = manager.new_group()
    if not opts.newgroup then
        group = manager.pop()
    end
    manager.add_to_group(group, window)
    manager.push(group, window)



    return window
end


return win
