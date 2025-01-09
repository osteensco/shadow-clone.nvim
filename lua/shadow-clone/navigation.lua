local manager = require('manager')
local utils = require('shadow-clone.utils')
local _win = require('shadow-clone.window')

local nav = {}


-- move current buffer into a new floating window (normal -> floating)
nav.bubble_up = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local count = vim.fn.winnr('$')
    if not utils.is_floating(win) and count > 1 then
        vim.api.nvim_win_close(win, true)
        _win.create_floating_window({ buf = buf, newgroup = true })
    end
end

-- move current buffer into the last accessed normal window (floating -> normal)
nav.bubble_down = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local anchor = vim.api.nvim_win_get_position(win)
        local group = manager.peek()
        assert(next(group),
            "Peek should not return an empty table when a floating window exists.")
        manager.remove_from_group(group, { bufnr = buf, win = win, anchor = { x = anchor[1], y = anchor[2] } })
        vim.api.nvim_win_close(win, true)
        vim.api.nvim_set_current_buf(buf)
    end
end

-- move current buffer into a horizontal split of the last accessed normal window (floating -> normal)
nav.bubble_down_h = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local anchor = vim.api.nvim_win_get_position(win)
        local group = manager.peek()
        assert(next(group),
            "Peek should not return an empty table when a floating window exists.")
        manager.remove_from_group(group, { bufnr = buf, win = win, anchor = { x = anchor[1], y = anchor[2] } })
        vim.api.nvim_win_close(win, true)
        vim.cmd("split")
        vim.api.nvim_set_current_buf(buf)
    end
end

-- move current buffer into a vertical split of the last accessed normal window (floating -> normal)
nav.bubble_down_v = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    if utils.is_floating(win) then
        local anchor = vim.api.nvim_win_get_position(win)
        local group = manager.peek()
        assert(next(group),
            "Peek should not return an empty table when a floating window exists.")
        manager.remove_from_group(group, { bufnr = buf, win = win, anchor = { x = anchor[1], y = anchor[2] } })
        vim.api.nvim_win_close(win, true)
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
        function(distance, farthest) return distance < 0 and (not farthest or farthest.distance < distance) end
    )
end

nav.move_right = function()
    move_to_closest(
        function(curr_pos, anchor_pos) return curr_pos[2] - anchor_pos[2] end,
        function(distance, closest) return distance < 0 and (not closest or closest.distance < distance) end,
        function(distance, farthest) return distance > 0 and (not farthest or farthest.distance > distance) end
    )
end

nav.move_up = function()
    move_to_closest(
        function(curr_pos, anchor_pos) return curr_pos[1] - anchor_pos[1] end,
        function(distance, closest) return distance < 0 and (not closest or closest.distance < distance) end,
        function(distance, farthest) return distance > 0 and (not farthest or farthest.distance > distance) end
    )
end

nav.move_down = function()
    move_to_closest(
        function(curr_pos, anchor_pos) return curr_pos[1] - anchor_pos[1] end,
        function(distance, closest) return distance > 0 and (not closest or closest.distance > distance) end,
        function(distance, farthest) return distance < 0 and (not farthest or farthest.distance < distance) end
    )
end


















-- -- Move to the closest left window in the same group.
-- -- Moves to the rightmost window if current window is the leftmost of the group.
-- nav.move_left = function()
--     local curr_win = vim.api.nvim_get_current_win()
--     if utils.is_floating(curr_win) and manager.get_len() > 0 then
--         ---@type WinGroup
--         local group = manager.peek()
--         assert(next(group),
--             "Peek should not return an empty table when a floating window exists.")
--
--         ---@type WindowDistance
--         local closest, farthest = nil, nil
--         local curr_pos = vim.api.nvim_win_get_position(curr_win)
--         for _, win in ipairs(group.members) do
--             if win.win ~= curr_win then
--                 local distance = curr_pos[2] - win.anchor[2]
--                 if distance > 0 and (not closest or closest.distance > distance) then
--                     closest = { distance = distance, winnr = win.win }
--                 elseif distance < 0 and (not farthest or farthest.distance < distance) then
--                     farthest = { distance = distance, winnr = win.win }
--                 end
--             end
--         end
--
--         if not closest and not farthest then
--             return
--         end
--
--         local destination = closest or farthest
--         vim.api.nvim_set_current_win(destination.winnr)
--     end
-- end
--
-- -- Move to the closest right window in the same group.
-- -- Moves to the leftmost window if current window is the rightmost of the group.
-- nav.move_right = function()
--     local curr_win = vim.api.nvim_get_current_win()
--     if utils.is_floating(curr_win) and manager.get_len() > 0 then
--         ---@type WinGroup
--         local group = manager.peek()
--         assert(next(group),
--             "Peek should not return an empty table when a floating window exists.")
--
--         ---@type WindowDistance
--         local closest, farthest = nil, nil
--         local curr_pos = vim.api.nvim_win_get_position(curr_win)
--         for _, win in ipairs(group.members) do
--             if win.win ~= curr_win then
--                 local distance = curr_pos[2] - win.anchor[2]
--                 if distance < 0 and (not closest or closest.distance < distance) then
--                     closest = { distance = distance, winnr = win.win }
--                 elseif distance > 0 and (not farthest or farthest.distance > distance) then
--                     farthest = { distance = distance, winnr = win.win }
--                 end
--             end
--         end
--
--         if not closest and not farthest then
--             return
--         end
--
--         local destination = closest or farthest
--         vim.api.nvim_set_current_win(destination.winnr)
--     end
-- end
--
-- -- Move to the closest window above current window in the same group.
-- -- Moves to the bottom most window if current window is the topmost of the group.
-- nav.move_up = function()
--     local curr_win = vim.api.nvim_get_current_win()
--     if utils.is_floating(curr_win) and manager.get_len() > 0 then
--         ---@type WinGroup
--         local group = manager.peek()
--         assert(next(group),
--             "Peek should not return an empty table when a floating window exists.")
--
--         ---@type WindowDistance
--         local closest, farthest = nil, nil
--         local curr_pos = vim.api.nvim_win_get_position(curr_win)
--         for _, win in ipairs(group.members) do
--             if win.win ~= curr_win then
--                 local distance = curr_pos[1] - win.anchor[1]
--                 if distance < 0 and (not closest or closest.distance < distance) then
--                     closest = { distance = distance, winnr = win.win }
--                 elseif distance > 0 and (not farthest or farthest.distance > distance) then
--                     farthest = { distance = distance, winnr = win.win }
--                 end
--             end
--         end
--
--         if not closest and not farthest then
--             return
--         end
--
--         local destination = closest or farthest
--         vim.api.nvim_set_current_win(destination.winnr)
--     end
-- end
--
-- -- Move to the closest window below current window in the same group.
-- -- Moves to the top most if current window is the bottom most of the group.
-- nav.move_down = function()
--     local curr_win = vim.api.nvim_get_current_win()
--     if utils.is_floating(curr_win) and manager.get_len() > 0 then
--         ---@type WinGroup
--         local group = manager.peek()
--         assert(next(group),
--             "Peek should not return an empty table when a floating window exists.")
--
--         ---@type WindowDistance
--         local closest, farthest = nil, nil
--         local curr_pos = vim.api.nvim_win_get_position(curr_win)
--         for _, win in ipairs(group.members) do
--             if win.win ~= curr_win then
--                 local distance = curr_pos[1] - win.anchor[1]
--                 if distance > 0 and (not closest or closest.distance > distance) then
--                     closest = { distance = distance, winnr = win.win }
--                 elseif distance < 0 and (not farthest or farthest.distance < distance) then
--                     farthest = { distance = distance, winnr = win.win }
--                 end
--             end
--         end
--
--         if not closest and not farthest then
--             return
--         end
--
--         local destination = closest or farthest
--         vim.api.nvim_set_current_win(destination.winnr)
--     end
-- end



return nav
