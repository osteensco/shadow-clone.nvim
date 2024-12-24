-- manages of all shadow-clone windows and their buffers
local manager = {}

-- book keeping data structure
manager.ledger = {
    float = {
        array = {},
        last_accessed = {},
    },
    normal = {
        array = {},
        last_accessed = {},
    },
}

-- methods
manager.get_len = function(type)
    return #manager.ledger[type].array
end

manager.append = function(type, win)
    manager.ledger[type].array[manager.get_len(type) + 1] = win
end



return manager
