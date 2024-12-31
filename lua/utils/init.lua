local utils = {}

-- ---@enum WindowPosition
-- local position = {
--     center = "center"
-- }

-- Generates an anchor for a window based on position, height, and width.
-- Anchor is a table containing cols and rows (represented as x, y) that neovim uses to anchor a window.
utils.get_pos = function(pos, win, width, height)
    local winanchor = {}
    -- TODO
    --  - remove valid window option if it never gets used anywhere
    if vim.api.nvim_win_is_valid(win) then -- currently, this portion isn't getting used
        winanchor = vim.api.nvim_win_get_position(win)
    else
        winanchor = { vim.o.lines, vim.o.columns }
    end

    local opts = {
        center = function(w, h)
            return {
                x = math.floor((winanchor[2] - w) / 2),
                y = math.floor((winanchor[1] - h) / 2),
            }
        end,
        -- TODO
        -- implement left, right, top, bottom
    }

    -- call appropriate function based on pos argument
    local anchor = opts[pos](width, height)

    return anchor
end

---Determine if a window is floating.
---@param window number The window ID.
---@return boolean
utils.is_floating = function(window)
    local win_type = vim.fn.win_gettype(window)
    if win_type == "popup" then
        return true
    end

    return false
end

---Determine if a window is a terminal.
---@param window number The window ID.
---@return boolean
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
