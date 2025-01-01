local navigation = require("shadow-clone.navigation")
local split = require("shadow-clone.split")
local default_config = require("shadow-clone.config")
local commands = require("shadow-clone.commands")


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





-- toggle a floating terminal, creates a new terminal buffer if float.term.last_accessed is nil
-- M.toggle_floating_terminal = function()
--     local term = manager.ledger.float.terminal.last_accessed
--     if not vim.api.nvim_win_is_valid(term.win) then
--         term = M.create_floating_window({ buf = term.buf })
--         -- TODO
--         --  - abstract into "terminal start" function
--         if vim.bo[term.buf].buftype ~= "terminal" then
--             vim.cmd.terminal()
--         end
--         manager.update_access(term)
--     else
--         vim.api.nvim_win_hide(term.win)
--     end
-- end



--TODO
-- - rework hide and toggle functions
-- - how to handle hidden buffers (hidden stack?)

-- hide current floating window
-- M.hide_floating_window = function()
--     local win = vim.api.nvim_get_current_win()
--     vim.api.nvim_win_hide(win)
-- end
--
-- -- toggle last accessed window
-- M.toggle_last_accessed_win = function()
--     local win = manager.ledger.float.window.last_accessed
--     if not vim.api.nvim_win_is_valid(win.win) then
--         win = M.create_floating_window({ buf = win.buf })
--     else
--         M.hide_floating_window()
--     end
-- end







return M
