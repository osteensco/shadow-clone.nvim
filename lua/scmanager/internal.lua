---@class Anchor
---@field x number
---@field y number

---@class WinObj
---@field bufnr number buffer number of a floating window
---@field win number window ID of a floating window
---@field anchor Anchor x, y coordinates that represents the window's anchor

---@class WinGroup
---@field members WinObj[]
---@field zindex number

---@class Hidden
---@field stack WinGroup[]
---@field toggle WinGroup[]

---@class Data
---@field stack WinGroup[]
---@field hidden Hidden

---@return Data
local function init_mngr()
    return {

        -- Manager's main stack containing floating windows.
        -- Floating windows are always part of a group, the stack represents the group's relative position on the z axis.
        -- There are some assumptions with the stack:
        --  - The stack should exactly correspond to the zindex of a window. The top of the stack having the highest z index.
        --  - The stack provides a more standardized way to set and manage zindex's of all floating windows.
        --  - The windows in the stack will always correspond to open windows in neovim.
        stack = {},

        -- Manage hidden groups.
        -- Maintains window and group configurations that aren't visibile but the user would like to reproduce at a later time.
        -- The 'toggle' slot is an array that should never exceed a length of 1.
        hidden = {
            stack = {},
            toggle = {}
        }
    }
end

---@type Data
local data = init_mngr()




local ops = {}

---Main Stack Operations

---get length of the manager's stack
---@return number
ops.get_len = function()
    return #data.stack
end

---Push a group onto manager's stack.
---This function is called when a new window is created, or an existing group is being moved out of 'hidden' state.
---@param group WinGroup
ops.push = function(group)
    local length = ops.get_len()
    local zindex = 1
    data.stack[length + 1] = group
    -- table.insert(data.stack, group)

    if length ~= 0 then
        zindex = data.stack[length].zindex + 1
    end

    group.zindex = zindex

    for _, win in ipairs(group) do
        vim.api.nvim_win_set_config(win, { zindex = zindex })
    end
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
    -- TODO
    --  - verify this loop isn't needed
    for i, g in ipairs(data.stack) do
        if i ~= 1 then
            g.zindex = g.zindex + 1
        else
            g.zindex = 1
        end
    end
end

---moves bottom group to the top of the stack, and shifts all other groups down one.
ops.cycle_backwards = function()
    local bottom = table.remove(data.stack, 1)
    ops.push(bottom)
end



---Hidden stack operations

ops.hidden_get_len = function()
    return #data.hidden.stack + #data.hidden.toggle
end

ops.hidden_toggle_occupied = function()
    assert(#data.hidden.toggle < 2,
        "the toggle slot in the hidden stack should never be more than 1. data.hidden.toggle - ",
        vim.inspect(data.hidden.toggle))

    if #data.hidden.toggle == 0 then
        return false
    end

    return true
end

ops.hidden_pop = function()
    local group
    local length = ops.hidden_get_len()

    group = table.remove(data.hidden.stack, length)

    return group
end

---hide highest zindex group
ops.hide_top_group = function()
    local group = ops.pop()
    group.zindex = 0
    table.insert(data.hidden.stack, group)
end

---toggle last accessed group
---@return WinGroup
ops.toggle_last_accessed_group = function()
    local group

    if ops.hidden_toggle_occupied() then
        group = table.remove(data.hidden.toggle, 1)
        ops.push(group)
        group = ops.peek()
        return group
    end

    group = ops.pop()
    group.zindex = 0
    table.insert(data.hidden.toggle, group)

    return group
end



--- Group Manipulation

---creates a new WinGroup
---@return WinGroup
ops.new_group = function()
    return { members = {}, zindex = 0 }
end

---adds window object to a group
---@param group WinGroup
---@param window WinObj
ops.add_to_group = function(group, window)
    assert(group.members,
        "A group attempting to be added to should have two fields (members, zindex), got - " .. vim.inspect(group))
    assert(group.zindex,
        "A group attempting to be added to should have two fields (members, zindex), got - " .. vim.inspect(group))
    table.insert(group.members, window)
end

---removes a window object from a group
---@param group WinGroup
---@param window WinObj
ops.remove_from_group = function(group, window)
    assert(window.bufnr,
        "Window needs to contain the field 'bufnr' in order to search the group for removal. Window - " ..
        vim.inspect(window))
    assert(window.win,
        "Window needs to contain the field 'win' in order to search the group for removal. Window - " ..
        vim.inspect(window))

    local found = false
    for pos, win in ipairs(group.members) do
        if win.bufnr == window.bufnr and win.win == window.win then
            found = true
            table.remove(group.members, pos)
            break
        end
    end

    assert(found,
        "The window provided was not found in the group, so it could not be removed. Group - " ..
        vim.inspect(group) .. " Window - " .. vim.inspect(window))

    if #group.members == 0 then
        -- assumption is this would only get called on group that is top of stack
        -- will need adjusting if not always the case
        ops.pop()
    end
end

---Set all window ID's in group to -1 (invalid window).
ops.hide_group_windows = function(group)
    for _, win in ipairs(group.members) do
        win.win = -1
    end
end

-- Helpers

---@return string
ops.inspect = function()
    return vim.inspect(data.stack)
end

---@return table<string, string>
ops.hidden_inspect = function()
    return {
        stack = vim.inspect(data.hidden.stack),
        toggle = vim.inspect(data.hidden.toggle)
    }
end

---Removes all floating windows from shadow-clone's data structure.
ops.clear = function()
    data = init_mngr()
end

return ops
