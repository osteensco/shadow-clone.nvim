local utils = require("shadow-clone.utils")

local M = {}

-- defaults
M.config = {
    float_window = {
        position = 'center',
        width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10))),
        height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5))),
    },
}


function M.create_floating_window()
    local opts = M.config.float_window

    local pos = utils.get_pos(opts.position, opts.width, opts.height)

    local win_config = {
        relative = "editor",
        width = opts.width,
        height = opts.height,
        col = pos.x,
        row = pos.y,
        style = "minimal",
        border = "double",
        -- need highlight group for background
    }

    local buf = vim.api.nvim_create_buf(false, true)

    return {
        win = vim.api.nvim_open_win(buf, true, win_config),
        buf = buf
    }
end

function M.setup(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts)
end

-- TODO REMOVE ME!!!!!
local window = M.create_floating_window()
print(window.win, window.buf)
