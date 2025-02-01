---@class Anchor
---@field x number
---@field y number

---@class WinObj
---@field bufnr number buffer number of a floating window
---@field win number window ID of a floating window
---@field anchor Anchor x, y coordinates that represents the window's anchor
---@field height number height of the window
---@field width number width of the window

---@class WinGroup
---@field members WinObj[]
---@field zindex number
---@field toggle_bufnr? integer

---@class ToggleTable
---@field slot WinGroup[]
---@field buffers table<integer, WinGroup>

---@class HiddenTable
---@field stack WinGroup[]
---@field toggle ToggleTable

---@class DataTable
---@field stack WinGroup[]
---@field hidden HiddenTable

---@return DataTable
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
        -- The toggle slot is an array that should never exceed a length of 1. This is a volatile slot that clears after each unhide toggle.
        -- The toggle buffers is a series of persisted slots that can only be explicitly cleared or altered.
        hidden = {
            stack = {},
            toggle = {
                slot = {},
                buffers = {
                    -- [0] = {},
                }
            }
        }
    }
end

---@type DataTable
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
end

---moves bottom group to the top of the stack, and shifts all other groups down one.
ops.cycle_backwards = function()
    local bottom = table.remove(data.stack, 1)
    ops.push(bottom)
end



---Hidden stack operations

ops.hidden_get_len = function()
    return #data.hidden.stack
end

---@param bufnr integer
---@param group WinGroup
ops.set_toggle_buffer = function(bufnr, group)
    group.toggle_bufnr = bufnr
    data.hidden.toggle.buffers[bufnr] = group
end

---@param bufnr integer
ops.clear_toggle_buffer = function(bufnr)
    data.hidden.toggle.buffers[bufnr] = nil
end

---@param bufnr integer
---@return WinGroup
ops.get_toggle_buffer = function(bufnr)
    assert(data.hidden.toggle.buffers[bufnr], "The toggle buffer is not currently allocated, toggle bufnr - " .. bufnr)
    return data.hidden.toggle.buffers[bufnr]
end

---Toggle a group located in the provided toggle buffer. Returns a WinGroup and a boolean represting whether or not the group was added to the main stack.
---@param bufnr integer
---@return WinGroup, boolean
ops.toggle_persisted_group = function(bufnr)
    for i, group in ipairs(data.stack) do
        if group.toggle_bufnr == bufnr then
            table.remove(data.stack, i)
            return group, false
        end
    end
    local newgrp = ops.new_group()
    ops.push(newgrp)
    local group = ops.get_toggle_buffer(bufnr)
    return group, true
end

ops.hidden_toggle_slot_occupied = function()
    assert(#data.hidden.toggle.slot < 2,
        "the hidden toggle slot should never be more than 1. data.hidden.toggle.slot - ",
        vim.inspect(data.hidden.toggle.slot))

    if #data.hidden.toggle.slot == 0 then
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
    ops.hide_group_windows(group)
end

---toggle last accessed group
---@return WinGroup, boolean
ops.toggle_last_accessed_group = function()
    local group
    local occupied = ops.hidden_toggle_slot_occupied()

    if occupied then
        group = table.remove(data.hidden.toggle.slot, 1)
        -- Add an empty new group to the main stack.
        -- This will be hydrated with the group this function returns by window.recon_group.
        local newgrp = ops.new_group()
        ops.push(newgrp)
    else
        group = ops.pop()
        group.zindex = 0
        table.insert(data.hidden.toggle.slot, group)
    end

    return group, occupied
end



--- Group Manipulation

---creates a new WinGroup
---@return WinGroup
ops.new_group = function()
    return { members = {}, zindex = 0, toggle_buffer = nil }
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
---@param group WinGroup
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

---@return table<string, table<string>>
ops.hidden_inspect = function()
    -- local buffers = {}
    -- local dict = data.hidden.toggle.buffers
    -- for k, v in pairs(dict) do
    --     buffers[k] = vim.inspect(v)
    -- end
    return {
        stack = vim.inspect(data.hidden.stack),
        toggle = {
            slot = vim.inspect(data.hidden.toggle.slot),
            buffers = vim.inspect(data.hidden.toggle.buffers)

        }
    }
end

---Removes all floating windows from shadow-clone's data structure.
ops.clear = function()
    data = init_mngr()
end

return ops
