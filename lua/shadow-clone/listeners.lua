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
    -- listener for when a window's buffer is switched to a different buffer
    -- other event options:
    --  - WinEnter, BufEnter
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = vim.api.nvim_create_augroup("shadow-clone-listener", { clear = true }),
        pattern = "*",
        callback = function(opts)
            -- identify current window and ensure it's floating
            local winId = vim.api.nvim_get_current_win()
            local bufnr = vim.api.nvim_get_current_buf()
            local win_config = vim.api.nvim_win_get_config(winId)
            if win_config.relative ~= "" then -- may need to check null here
                -- identify current shadow-clone group
                --
                -- **ASSUPTION** any time a floating window's buffer changes, it should be part of the group at the top of the stack
                --  - tests will need to verify this is always the case
                local group = manager.peek()

                -- update buffer for given window in given group to switched buffer
                for _, win in ipairs(group.members) do
                    if win.win == winId then
                        win.bufnr = bufnr
                        break
                    end
                end
                -- TODO
                --  - assertion for case where window isn't found (it should always be found)
            end
        end
    })



    -- listener for a new window being created
    vim.api.nvim_create_autocmd("WinNew", {
        group = vim.api.nvim_create_augroup("shadow-clone-listener", { clear = true }),
        pattern = "*",
        callback = function(opts)
            local winId = vim.api.nvim_get_current_win()
            local bufnr = vim.api.nvim_get_current_buf()
            local win_config = vim.api.nvim_win_get_config(winId)
            if win_config.relative ~= "" then -- may need to check null here
                -- use a defer function?
                vim.defer_fn()

                -- PROBLEM:
                --  - window not created by shadow-clone won't be a part of a group
                --      - a new window created outside of shadow-clone will have an unpredictable zindex value
                --      - a new window created by shadow-clone should always have the highest zindex and be at the top of the stack
                --      - if multiple windows are created sequentially (like a telescope picker) then each new window would likely
                --        end up being placed in a new group erroneously
                --
                -- SOLUTION
                --  - check custom window variable https://neovim.io/doc/user/lua.html#vim.w
                --  - shadow-clone should impelement a rule stating within a certain window (100ms)
                --    all created windows are assumed to be part of the same group
                --      - this may need to be 50ms since last new window, which would implement a more dynamic timeout
                --  - need to implement a "new group cache" to collect all new windows part of a new group before pushing to the stack
                --  - likely need to make use of vim.schedule or vim.schedule_wrap
                --
                -- ASSUMPTIONS
                --  - any new window should belong top of stack group or a new group
                --  - any window created should either be created by shadow-clone or not
                --  - only windows not created by shadow-clone need to be tracked to see if they are part of a predetermined setup (like a telescope picker)
                --  - if a predetermined window passes without an additional floating window being created, any subsequent new windows should be in a new group
                --
                local shadow_clone = vim.w[winId].sc
                if not shadow_clone then
                    -- determine if new group needs to be created
                    -- add window to appropriate group
                    -- update manager's stack
                end
            end
        end
    })



    -- listener for a floating window being closed (not hidden)
end




listener.init()
-- return listener
