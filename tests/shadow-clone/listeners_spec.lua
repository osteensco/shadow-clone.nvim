local listeners = require("shadow-clone.listeners")
local window = require("shadow-clone.window")
local config = require("shadow-clone.config")
local manager = require("scmanager")

describe("listeners.lua |", function()
    after_each(function()
        manager.clear()
        vim.api.nvim_create_augroup("shadow-clone-listener", { clear = true })
    end)

    describe("buffer change", function()
        it("Buffer should reflect new bufnr after bufnr changed.", function()
            local win = window.create_floating_window()

            local newbuf = vim.api.nvim_create_buf(false, true)
            vim.api.nvim_win_set_buf(win.win, newbuf)
            vim.api.nvim_set_current_win(win.win)

            -- init listeners after window/buffer setup
            listeners.init()
            vim.api.nvim_exec_autocmds("BufEnter", {})
            vim.wait(100)

            local group = manager.peek()
            assert.are_equal(newbuf, group.members[1].bufnr)
        end)
    end)

    describe("window created", function()
        it("Window created by shadow-clone should not be duplicated.", function()
            window.create_floating_window()

            listeners.init()
            assert.are_equal(manager.get_len(), 1, "Only one group should exist in the stack.")
        end)

        it("Window not created by shadow-clone should exist in the manager's stack.", function()
            local buf = vim.api.nvim_create_buf(false, true)
            local winnr = vim.api.nvim_open_win(buf, true, config.win_config)

            -- init listeners after window/buffer setup
            listeners.init()
            vim.api.nvim_exec_autocmds("WinNew", {})
            vim.wait(100)

            assert.are_equal(manager.get_len(), 1, "A group should exist in the stack.")
            local group = manager.peek()
            assert.are_equal(#group.members, 1, "There should only be 1 memeber in the group.")
            assert.are_equal(group.members[1].win, winnr,
                "The window id for the only memeber of the group should be the window id from the window we created.")
        end)
    end)
end)
