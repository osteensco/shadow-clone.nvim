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

---@class Data
---@field stack WinGroup[]
---@field hidden WinGroup[]
local data = {}

-- Manager's main stack containing floating windows.
-- Floating windows are always part of a group, the stack represents the group's relative position on the z axis.
-- There are some assumptions with the stack:
--  - The stack should exactly correspond to the zindex of a window. The top of the stack having the highest z index.
--  - The stack will provide a more standardized way to set and manage zindex's of all floating windows.
--  - When a push operation occurs, the group is pushed onto the stack and the member that triggered the push will be provided to this function.
data.stack = {}

-- Manage hidden buffers
data.hidden = {}



local ops = {}

---get length of the manager's stack
---@return number
ops.get_len = function()
    return #data.stack
end

---Push a group onto manager's stack.
---When this function is called there should always be a new member associated with that group.
---This is either the first member or the latest addition. Either way it will always be pushed onto the stack.
---@param group WinGroup
---@param win WinObj
ops.push = function(group, win)
    local length = ops.get_len()
    local zindex = 1
    data.stack[length + 1] = group

    if length ~= 0 then
        zindex = data.stack[length].zindex + 1
    end

    group.zindex = zindex
    vim.api.nvim_win_set_config(win.win, { zindex = zindex })
end

---pop a group off the manager's stack
---@return WinGroup
ops.pop = function()
    local length = ops.get_len()
    local group = table.remove(data.stack, length)
    return group
end

---peek at the top of the manager's stack
---@return WinGroup
ops.peek = function()
    local length = ops.get_len()
    if length < 1 then
        return {}
    end
    return data.stack[length]
end

---swaps the group on top of the stack with the group directly below
ops.swap = function()
    local length = ops.get_len()
    if length <= 1 then
        return
    end

    local top = data.stack[length]
    local topidx = data.stack[length].zindex
    local bott = data.stack[length - 1]
    local bottidx = data.stack[length].zindex
    data.stack[length] = bott
    data.stack[length].zindex = bottidx
    data.stack[length - 1] = top
    data.stack[length - 1].zindex = topidx
end

---pops a group off the stack, moves it to the bottom, and shifts all other groups up one.
ops.cycle = function()
    local top = ops.pop()
    table.insert(data.stack, 1, top)
    for i, g in ipairs(data.stack) do
        if i ~= 1 then
            g.zindex = g.zindex + 1
        else
            g.zindex = 1
        end
    end
end

---creates a new WinGroup
---@return WinGroup
ops.new_group = function()
    return { members = {}, zindex = 0 }
end

---adds window object to a group
---@param group WinGroup
---@param window WinObj
ops.add_to_group = function(group, window)
    group = group or ops.new_group()
    table.insert(group.members, window)
end

---removes a window object from a group
---@param group WinGroup
---@param window WinObj
ops.remove_from_group = function(group, window)
    for pos, win in ipairs(group.members) do
        if win.bufnr == window.bufnr and win.win == window.win then
            table.remove(group.members, pos)
            break
        end
    end
    if #group.members == 0 then
        -- assumption is this would only get called on group that is top of stack
        -- will need adjusting if not always the case
        ops.pop()
    end
    -- TODO
    --  - handle not finding the window object in the group
end


ops.inspect = function()
    print(vim.inspect(data.stack))
end

return ops
