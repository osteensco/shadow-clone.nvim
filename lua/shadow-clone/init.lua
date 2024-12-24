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

    local win_config = opts.win_config or {
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

    manager.append('float', window)

    return window
end


-- commands
vim.api.nvim_create_user_command("SCwindow", M.create_floating_window, { nargs = '?' })
-- vim.api.nvim_create_user_command("SCtoggle", M.toggle_floating_window, { nargs = '?' })



-- setup function
M.setup = function(config)
    config = config or {}
    M.config = vim.tbl_deep_extend('force', M.config, config)
end

-- TODO REMOVE ME!!!!!
-- M.create_floating_window()
-- print(vim.inspect(M.manager.float[1]))


return M
