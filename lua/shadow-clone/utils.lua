local utils = {}

function utils.get_pos(pos, width, height)
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

return utils
