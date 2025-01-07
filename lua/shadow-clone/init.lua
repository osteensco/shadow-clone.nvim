local navigation = require("shadow-clone.navigation")
local split = require("shadow-clone.split")
local default_config = require("shadow-clone.config")
local commands = require("shadow-clone.commands")
local keymaps = require("shadow-clone.keymaps")


local M = {}

M.config = default_config

--API methods
M.navigation = navigation
M.split = split

-- setup function
---@param config? Config
M.setup = function(config)
    config = config or {}
    M.config = vim.tbl_deep_extend('force', M.config, config)
end


-- Set commands
commands.init()
-- Set keymaps
keymaps.init()











return M
