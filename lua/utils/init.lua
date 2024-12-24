local utils = {}

utils.get_pos = function(pos, width, height)
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

-- returns float/normal and terminal/window
utils.get_types = function(window)
    local win_type = vim.fn.win_gettype(window.win)
    if win_type == "popup" then
        win_type = "float"
    else
        win_type = "normal"
    end
    local buf_type = vim.bo[window.buf].buftype
    if buf_type ~= "terminal" then
        buf_type = "window"
    end

    return win_type, buf_type
end



return utils
