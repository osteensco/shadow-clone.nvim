local manager = require('scmanager')
local utils = require('shadow-clone.utils')
local _win = require('shadow-clone.window')

local nav = {}


-- move current buffer into a new floating window (normal -> floating)
nav.bubble_up = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local count = vim.fn.winnr('$')
    if not utils.is_floating(win) and count > 1 then
        vim.api.nvim_win_hide(win)
        _win.create_floating_window({ buf = buf, newgroup = true })
    end
end

-- move current buffer into the last accessed normal window (floating -> normal)
nav.bubble_down = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local group = manager.peek()
        assert(next(group),
            "Peek should not return an empty table when a floating window exists.")
        manager.remove_from_group(group, { bufnr = buf, win = win })
        vim.api.nvim_win_hide(win)
        vim.api.nvim_set_current_buf(buf)
    end
end

-- move current buffer into a horizontal split of the last accessed normal window (floating -> normal)
nav.bubble_down_h = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local group = manager.peek()
        assert(next(group),
            "Peek should not return an empty table when a floating window exists.")
        manager.remove_from_group(group, { bufnr = buf, win = win })
        vim.api.nvim_win_hide(win)
        vim.cmd("split")
        vim.api.nvim_set_current_buf(buf)
    end
end

-- move current buffer into a vertical split of the last accessed normal window (floating -> normal)
nav.bubble_down_v = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local group = manager.peek()
        assert(next(group),
            "Peek should not return an empty table when a floating window exists.")
        manager.remove_from_group(group, { bufnr = buf, win = win })
        vim.api.nvim_win_hide(win)
        vim.cmd("vsplit")
        vim.api.nvim_set_current_buf(buf)
    end
end



---@class WindowDistance
---@field distance integer
---@field winnr integer

---@param get_distance fun(curr_pos: integer[], anchor: integer[],): integer
---@param is_closest fun(distance: integer, closest: WindowDistance): boolean
---@param is_farthest fun(distance: integer, farthest: WindowDistance): boolean
local function move_to_closest(get_distance, is_closest, is_farthest)
    local curr_win = vim.api.nvim_get_current_win()
    if utils.is_floating(curr_win) then
        ---@type WinGroup
        local group = manager.peek()
        assert(next(group),
            "Peek() should not return an empty table when a floating window exists.")

        ---@type WindowDistance
        local closest, farthest = nil, nil
        local curr_pos = vim.api.nvim_win_get_position(curr_win)
        assert(curr_pos ~= nil, "curr_pos should never be nil. - curr_win: " .. curr_win)

        for _, win in ipairs(group.members) do
            if win.win ~= curr_win then
                local distance = get_distance(curr_pos, win.anchor)
                if is_closest(distance, closest) then
                    closest = { distance = distance, winnr = win.win }
                elseif is_farthest(distance, farthest) then
                    farthest = { distance = distance, winnr = win.win }
                end
            end
        end

        if not closest and not farthest then
            return
        end

        local destination = closest or farthest
        vim.api.nvim_set_current_win(destination.winnr)
    end
end


nav.move_left = function()
    move_to_closest(
        function(curr_pos, anchor_pos) return curr_pos[2] - anchor_pos[2] end,
        function(distance, closest) return distance > 0 and (not closest or closest.distance > distance) end,
        function(distance, farthest)
            return (distance < 0 or not farthest or math.abs(distance) > math.abs(farthest.distance))
        end

    )
end

nav.move_right = function()
    move_to_closest(
        function(curr_pos, anchor_pos) return curr_pos[2] - anchor_pos[2] end,
        function(distance, closest) return distance < 0 and (not closest or closest.distance < distance) end,
        function(distance, farthest)
            return (distance < 0 or not farthest or math.abs(distance) > math.abs(farthest.distance))
        end
    )
end

nav.move_up = function()
    move_to_closest(
        function(curr_pos, anchor_pos) return curr_pos[1] - anchor_pos[1] end,
        function(distance, closest) return distance > 0 and (not closest or closest.distance > distance) end,
        function(distance, farthest)
            return (distance < 0 or not farthest or math.abs(distance) > math.abs(farthest.distance))
        end
    )
end

nav.move_down = function()
    move_to_closest(
        function(curr_pos, anchor_pos) return curr_pos[1] - anchor_pos[1] end,
        function(distance, closest) return distance < 0 and (not closest or closest.distance < distance) end,
        function(distance, farthest)
            return (distance < 0 or not farthest or math.abs(distance) > math.abs(farthest.distance))
        end
    )
end





return nav
