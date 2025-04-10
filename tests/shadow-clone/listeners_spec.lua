local listeners = require("shadow-clone.listeners")
local window = require("shadow-clone.window")
local utils = require("shadow-clone.utils")
local manager = require("scmanager")

describe("listeners.lua", function()
    before_each(function()
        -- listeners.init()
    end)

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

            listeners.init()
            vim.api.nvim_exec_autocmds("BufEnter", {})

            vim.wait(100)
            local group = manager.peek()
            assert.are_equal(newbuf, group.members[1].bufnr)
        end)
    end)

    describe("window created", function()
        -- TODO
        -- implement test
    end)
end)
