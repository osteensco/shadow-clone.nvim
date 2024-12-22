local M = {}

M.config = {}

M.default_opts = {
    float_window = {
        position = 'center',
        width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10))),
        height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5))),
    },

}

local function get_pos(pos, width, height)
    local opts = {
        center = function(w, h)
            return {
                x = math.floor((vim.o.columns - w) / 2),
                y = math.floor((vim.o.lines - h) / 2),
            }
        end,
        -- TODO
        -- left, right, top, bottom
    }
    local position = opts[pos](width, height)
    return position
end

function M.create_floating_window()
    local opts = M.default_opts.float_window

    local pos = get_pos(opts.position, opts.width, opts.height)

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
