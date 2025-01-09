local nav = require('shadow-clone.navigation')
local utils = require('shadow-clone.utils')
local _win = require('shadow-clone.window')
local manager = require('manager')
local mock = require('luassert.mock')
local stub = require('luassert.stub')



local current_win = 1
local current_buf = 2
local buf_counter = 1
local win_counter = 1
local windows = {} -- mock neovim's window management



describe('navigation.lua', function()
    before_each(function()
        current_win = 1
        current_buf = 2
        buf_counter = 1
        win_counter = 1

        --TODO
        -- - create proper mocks
        -- - add helper vars
        -- - figure out how to mock tracking normal windows

        stub(vim.fn, 'winnr', function() return 2 end)
        stub(vim.api, 'nvim_get_current_win', function() return current_win end)
        stub(vim.api, 'nvim_get_current_buf', function() return current_buf end)

        stub(vim.api, 'nvim_buf_is_valid', function(bufnr) return true end)
        stub(vim.api, "nvim_create_buf", function()
            local bufnr = buf_counter
            buf_counter = bufnr + 1
            return bufnr
        end)
        stub(vim.api, "nvim_open_win", function(buffer, enter, config)
            local winnr = win_counter
            win_counter = winnr + 1

            windows[winnr] = config
            windows[winnr].buf = buffer

            return winnr
        end)

        stub(vim.api, 'nvim_set_current_win')
        stub(vim.api, 'nvim_win_get_position', function() return { 1, 1 } end)
        stub(vim.api, 'nvim_win_get_height', function() return 10 end)
        stub(vim.api, 'nvim_win_get_width', function() return 10 end)
        stub(vim.api, 'nvim_win_close', function() end)
        stub(vim.api, 'nvim_set_current_buf', function() end)
    end)

    after_each(function()
        mock.revert(vim.api)
        mock.revert(vim.fn)
        mock.revert(utils)
    end)

    -- bubble functions care about:
    --  - adding and removing from the stack
    --  - transfering the current buffer successfully
    describe('bubble_up()', function()
        stub(utils, 'is_floating', function() return false end)

        it('should move buffer to a floating window', function()
            nav.bubble_up()

            assert.equals(1, manager.get_len())
            local grp = manager.peek()
            assert.equals(1, #grp.members)
            assert.equals(windows[1].buf, grp.members[1].bufnr)
        end)
    end)

    describe('bubble_down()', function()
        it('should move buffer from floating to normal window', function()
            nav.bubble_down()
            -- assert stack is empty (or 1 less)
            --  - window's buffer should equal original floating window's buffer
        end)
    end)

    describe('bubble_down_h()', function()
        it('should move buffer from floating to horizontal split', function()
            nav.bubble_down_h()
            -- assert stack is empty (or 1 less)
            --  - current buffer should equal original floating window's buffer
            --  - other window's buffer should be preserved
        end)
    end)

    describe('bubble_down_v()', function()
        it('should move buffer from floating to vertical split', function()
            nav.bubble_down_v()
            -- assert stack is empty (or 1 less)
            --  - current buffer should equal original floating window's buffer
            --  - other window's buffer should be preserved
        end)
    end)


    -- movement functions really only care about window anchor points
    describe('move_left()', function()
        it('should move to the closest left window in the same group', function()
            -- assert lesser col value
        end)

        it('should move to the farthest right window in the same group if currently in the leftmost window', function()
            -- assert max col value from position
        end)

        it('should move left successfully more than once', function()
            -- cycle through 3 windows until at original window, assert after each call
        end)
    end)

    describe('move_right()', function()
        it('should move to the closest right window in the same group', function()
            -- assert greater col value
        end)

        it('should move to the farthest left window in the same group if currently in the rightmost window', function()
            -- assert min col value from position
        end)

        it('should move right successfully more than once', function()
            -- cycle through 3 windows until at original window, assert after each call
        end)
    end)

    describe('move_up()', function()
        it('should move to the closest window above in the same group', function()
            -- assert lesser row value
        end)

        it('should move to the bottom most window in the same group if currently in the top most window', function()
            -- assert min row value from position
        end)

        it('should move up successfully more than once', function()
            -- cycle through 3 windows until at original window, assert after each call
        end)
    end)

    describe('move_down()', function()
        it('should move to the closest window below in the same group', function()
            -- assert greater row value
        end)

        it('should move to the top most window in the same group if currently in the bottom most window', function()
            -- assert max row value from position
        end)

        it('should move down successfully more than once', function()
            -- cycle through 3 windows until at original window, assert after each call
        end)
    end)
end)
