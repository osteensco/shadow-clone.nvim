-- setup function defaults

---@class FloatConfig Float window settings.
---@field position string String representing how the window is anchored (center, left, right, top, bottom).
---@field width number
---@field height number

---@class Config Settings passed to setup function that shadow-clone.nvim uses.
---@field float_window? FloatConfig
---@field DEBUG? boolean
local config = {
    float_window = {
        position = 'center',
        -- TODO
        -- height/width % and minimums should be passed in
        width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10))),
        height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5))),
    },
    DEBUG = false,
}

return config
