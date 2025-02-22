local manager = require('scmanager')
-- TODO
--  - implement floating window open/close listener
--  - use listener to add/remove floating windows from main stack
--  - figure out:
--      - how to distinguish shadow-clone's create floating window vs other sources
--      - how to handle something like telescope picker?
--  - implement buffer change listener
--  - when a group memember's buffer changes, this needs to be updated in the stack accordingly



local listener = {}

listener.init = function()
    -- other event options:
    --  - WinEnter, BufEnter
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = vim.api.nvim_create_augroup("shadow-clone-listener", { clear = true }),
        pattern = "*",
        callback = function(opts)
            -- identify current window
            local winId = vim.api.nvim_get_current_win()
            local bufnr = vim.api.nvim_get_current_buf()
            -- identify current shadow-clone group
            -- TODO
            --  - handle windows not created by shadow-clone
            --      - group id needs to be a field in winObj or a lookup table needs to be added to the manager's data structure
            local group = manager.peek()

            -- update buffer for given window in given group to switched buffer
            for _, win in ipairs(group.members) do
                if win.win == winId then
                    win.bufnr = bufnr
                end
            end
        end
    })
end





return listener
