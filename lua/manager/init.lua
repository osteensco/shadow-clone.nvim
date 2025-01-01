-- shadow clone manager

---@class Anchor
---@field x number
---@field y number

---@class WinObj
---@field bufnr number buffer number of a floating window
---@field win number window ID of a floating window
---@field anchor Anchor x, y coordinates that represents the window's anchor

---@class WinGroup
---@field members table<WinObj>
---@field zindex number

--- Manages all floating window buffers
---@class Manager
---@field stack table<WinGroup>
local manager = {}

-- Manager's main stack containing floating windows.
-- Floating windows are always part of a group, the stack represents the group's relative position on the z axis.
-- There are some assumptions with the stack:
--  - The stack should exactly correspond to the zindex of a window. The top of the stack having the highest z index.
--  - The stack will provide a more standardized way to set and manage zindex's of all floating windows.
--  - When a push operation occurs, the group is pushed onto the stack and the member that triggered the push will be provided to this function.
manager.stack = {}
-- TODO
--  - ON ALL METHODS
--      - adjust zindex of window to correspond with stack position
--  - Handle hidden buffers.


-- methods

---get length of the manager's stack
---@return number
manager.get_len = function()
    return #manager.stack
end

---Push a group onto manager's stack.
---When this function is called there should always be a new member associated with that group.
---This is either the first memeber or the latest addition. Either way it will always be pushed onto the stack.
---@param group WinGroup
---@param win WinObj
manager.push = function(group, win)
    local length = manager.get_len()
    manager.stack[length + 1] = group

    -- add zindex if there isn't one
    if not group.zindex then
        local zindex = manager.stack[length].zindex + 1
        vim.api.nvim_win_set_config(win, {zindex = zindex})    
    end
end

---pop a group off the manager's stack
---@return WinGroup
manager.pop = function()
    local length = manager.get_len()
    local group = manager.stack[length]
    table.remove(manager.stack, length)
    return group
end

---peak at the top of the manager's stack
---@return WinGroup
manager.peak = function()
    local length = manager.get_len()
    if length <= 1 then
        return {}
    end
    return manager.stack[length]
end

---swaps the group on top of the stack with the group directly below
manager.swap = function()
    local length = manager.get_len()
    if length <= 1 then
        return
    end

    local top = manager.stack[length]
    local topidx = manager.stack[length].zindex
    local bott = manager.stack[length - 1]
    local bottidx = manager.stack[length].zindex
    manager.stack[length] = bott
    manager.stack[length].zindex = bottidx
    manager.stack[length - 1] = top
    manager.stack[length - 1].zindex = topidx
    
end



---adds window object to a group
---@param group WinGroup
---@param window WinObj
manager.add_to_group = function(group, window)
    group = group or {}
    table.insert(group, window)
end

---removes a window object from a group
---@param group WinGroup
---@param window WinObj
manager.remove_from_group = function(group, window)
    for pos, win in ipairs(group) do
        if win.bufnr == window.bufnr and win.win == window.win then
            table.remove(group, pos)
            return
        end
    end
    -- TODO
    --  - handle not finding the window object in the group
end






return manager
