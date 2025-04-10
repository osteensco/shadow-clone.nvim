local utils = require("shadow-clone.utils")



-- setup function defaults

---@class Config Settings passed to setup function that shadow-clone.nvim uses.
---@field win_config? vim.api.keyset.win_config
---@field position? string String representing how the window is anchored (center, left, right, top, bottom).
---@field DEBUG? boolean Option used to display additional info on header of floating windows.



local config = {
    win_config = {
        relative = "editor",
        width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10))),
        height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5))),
        col = 0, -- This will be set by the setup function depending on what 'position is set to'
        row = 0, -- This will be set by the setup function depending on what 'position is set to'
        style = "minimal",
        border = "rounded",
        -- TODO
        -- need highlight group for background
    },
    position = 'center',
    -- TODO
    -- height/width % and minimums should be passed in
    DEBUG = false,
}



return config
