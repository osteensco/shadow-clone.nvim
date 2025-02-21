local window = require("shadow-clone.window")
local navigation = require("shadow-clone.navigation")
local split = require("shadow-clone.split")
local default_config = require("shadow-clone.config")
local commands = require("shadow-clone.commands")
local keymaps = require("shadow-clone.keymaps")
local utils = require("shadow-clone.utils")


local M = {}

M.config = default_config

--API methods
M.navigation = navigation
M.split = split
M.win = {
    new = window.create_floating_window,
    group = {
        hide = window.hide_group,
        unhide = window.unhide_group,
        unhidetop = window.unhide_top,
        toggle = window.toggle_group,
        togglebuf = window.toggle_persisted_group,
        togglebufassign = window.toggle_assign_buffer,
        getcurr = window.get_top_group,
    }
}

M.debug = {
    inspect = utils.inspect,
    inspect_hidden = utils.inspect_hidden,
}

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
