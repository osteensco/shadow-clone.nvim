local utils = {}

-- returns table containing cols and rows (represented as x, y) neovim uses to anchor window
utils.get_pos = function(pos, width, height)
    local opts = {
        center = function(w, h)
            return {
                x = math.floor((vim.o.columns - w) / 2),
                y = math.floor((vim.o.lines - h) / 2),
            }
        end,
        -- TODO
        -- implement left, right, top, bottom
    }

    -- call appropriate function based on pos argument
    local position = opts[pos](width, height)

    return position
end

-- determine if a window is floating
utils.is_floating = function(window)
    local win_type = vim.fn.win_gettype(window)
    if win_type == "popup" then
        return true
    end

    return false
end

-- determine if a window is a terminal
utils.is_terminal = function(window)
    local buf_type = vim.bo[window].buftype
    if buf_type == "terminal" then
        return true
    end

    return false
end

-- returns window type float/normal and buffer type terminal/window
utils.get_types = function(window)
    local win_type = "normal"
    local buf_type = "window"

    if utils.is_floating(window.win) then
        win_type = "float"
    end

    if utils.is_terminal(window.buf) then
        buf_type = "terminal"
    end

    return win_type, buf_type
end




return utils
