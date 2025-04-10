local manager = require('scmanager')
local config = require('shadow-clone.config')

-- Why Are Listeners Needed?
-- PROBLEM:
--  - window not created by shadow-clone won't be a part of a group
--      - a new window created outside of shadow-clone will have an unpredictable zindex value
--      - a new window created by shadow-clone should always have the highest zindex and be at the top of the stack
--      - if multiple windows are created sequentially (like a telescope picker) then each new window would likely
--        end up being placed in a new group erroneously
--  - similarly, any buffer change or window close would not be reflected in shadow-clone's stack
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



local listener = {}

listener.group_cache = {}
listener.group_timer = nil
listener.debounce_ms = 50

listener.init = function()
    local groupid = vim.api.nvim_create_augroup("shadow-clone-listener", { clear = true })



    -- CURRENT ISSUE: It might be possible for BufEnter to happen before the manager has had a chance to update it's stack. Need to account for this.
    -- Listener for when a window's buffer is switched to a different buffer.
    vim.api.nvim_create_autocmd("BufEnter", {
        group = groupid,
        pattern = "*",
        callback = function()
            local winId = vim.api.nvim_get_current_win()
            local bufnr = vim.api.nvim_get_current_buf()
            local win_config = vim.api.nvim_win_get_config(winId)
            -- we only care about floating windows
            if win_config.relative ~= "" then
                -- The assumption is that any time a floating window's buffer changes, that window should be part of the group at the top of the stack
                local group = manager.peek()
                local win, window_found = manager.query_group(group, winId)
                -- Assert our previously mentioned assumption
                assert(window_found, "Window with id " .. win.win .. "was not found in group top of stack.")
                assert(win.bufnr,
                    "Window object for id " .. win.win .. " is missing the bufnr field. - " .. vim.inspect(win))
                if win.bufnr ~= bufnr then
                    win.bufnr = bufnr
                end
            end
        end
    })



    -- Listener for a new window being created.
    vim.api.nvim_create_autocmd("WinNew", {
        group = groupid,
        pattern = "*",
        callback = function(opts)
            local group = {}
            group.win = vim.api.nvim_get_current_win()
            group.buf = vim.api.nvim_get_current_buf()
            group.config = vim.api.nvim_win_get_config(group.win)
            -- we only care about floating windows
            if group.config.relative ~= "" then
                -- return early if the window was created by shadow-clone
                local ok, _ = pcall(vim.api.nvim_get_var, group.win, "sc")
                if ok then
                    return
                end

                table.insert(listener.group_cache, group)

                -- we want to check if a timer is already running and reset it
                -- this creates a 'timeout' rule from the last opened window to close off the current group that is being populated
                if listener.group_timer then
                    listener.group_timer:stop()
                    listener.group_timer:close()
                end

                -- defer_fn returns our timer object
                listener.group_timer = vim.defer_fn(function()
                    for _, g in ipairs(listener.group_cache) do
                        print("!!!!!!!! - ?", vim.inspect(g))
                        manager.manifest_window(g.buf, g.win, g.config, true, config.DEBUG)
                    end

                    -- reset cache and timer
                    listener.group_cache = {}
                    listener.group_timer = nil
                end, listener.debounce_ms)
            end
        end
    })



    -- listener for a floating window being closed completely




    -- listener for a floating window being hidden
end




-- listener.init()
return listener
