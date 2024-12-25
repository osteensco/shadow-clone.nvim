local utils = require("utils")
-- manages of all shadow-clone windows and their buffers
local manager = {}

-- book keeping data structure
manager.ledger = {
    -- TODO
    --  - merge terminal and window objects
    --  - convert to a stack, removes the need for last_accessed
    float = {
        terminal = {
            array = {},
            last_accessed = { win = -1, term = -1 },
        },
        window = {
            array = {},
            last_accessed = { win = -1, term = -1 },
        }
    },
    normal = {
        terminal = {
            array = {},
            last_accessed = { win = -1, term = -1 },
        },
        window = {
            array = {},
            last_accessed = { win = -1, term = -1 },
        }
    },
}

-- methods
manager.get_len = function(win_type, buf_type)
    return #manager.ledger[win_type][buf_type].array
end

manager.update_access = function(win)
    local win_type, buf_type = utils.get_types(win)
    manager.ledger[win_type][buf_type].last_accessed = win
end

manager.append = function(win)
    local win_type, buf_type = utils.get_types(win)
    local length = manager.get_len(win_type, buf_type)
    manager.ledger[win_type][buf_type].array[length + 1] = win
    manager.update_access(win)
end

manager.remove = function()
    -- TODO
end

manager.set_win_type = function(win)
    -- TODO
end

manager.set_buf_type = function(win)
    -- TODO
end



return manager
