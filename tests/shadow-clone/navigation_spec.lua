local nav = require('shadow-clone.navigation')
local utils = require('shadow-clone.utils')
local manager = require('manager')
local _win = require('shadow-clone.window')

describe('Navigation module tests', function()
    local current_win, current_buf

    before_each(function()
        -- Mocking Vim API
        current_win = 1
        current_buf = 2

        -- Mock Vim API calls
        stub(vim.api, 'nvim_get_current_win', function() return current_win end)
        stub(vim.api, 'nvim_get_current_buf', function() return current_buf end)
        stub(vim.api, 'nvim_set_current_win')
        stub(vim.api, 'nvim_win_get_position', function() return { 1, 1 } end) -- Position mock
        stub(vim.api, 'nvim_win_get_height', function() return 10 end)       -- Mock height
        stub(vim.api, 'nvim_win_get_width', function() return 10 end)        -- Mock width
        stub(vim.api, 'nvim_win_close')
        stub(vim.api, 'nvim_set_current_buf')

        -- Mock manager functions
        stub(manager, 'peek', function() return { members = { { win = current_win } } } end)
        stub(manager, 'get_len', function() return 1 end)
        stub(manager, 'remove_from_group')
    end)

    after_each(function()
        -- Reset the mocks after each test
        stub(vim.api, 'nvim_get_current_win'):revert()
        stub(vim.api, 'nvim_get_current_buf'):revert()
        stub(vim.api, 'nvim_set_current_win'):revert()
        stub(vim.api, 'nvim_win_get_position'):revert()
        stub(vim.api, 'nvim_win_get_height'):revert()
        stub(vim.api, 'nvim_win_get_width'):revert()
        stub(vim.api, 'nvim_win_close'):revert()
        stub(vim.api, 'nvim_set_current_buf'):revert()

        stub(manager, 'peek'):revert()
        stub(manager, 'get_len'):revert()
        stub(manager, 'remove_from_group'):revert()
    end)

    describe('bubble_up', function()
        it('should move buffer to a floating window', function()
            stub(utils, 'is_floating', function() return false end) -- Mock non-floating window
            nav.bubble_up()
            assert.stub(vim.api.nvim_win_close).was_called()
            assert.stub(_win.create_floating_window).was_called()
        end)
    end)

    describe('bubble_down', function()
        it('should move buffer from floating to normal window', function()
            stub(utils, 'is_floating', function() return true end) -- Mock floating window
            nav.bubble_down()
            assert.stub(vim.api.nvim_win_close).was_called()
            assert.stub(vim.api.nvim_set_current_buf).was_called_with(current_buf)
        end)
    end)

    describe('bubble_down_h', function()
        it('should move buffer from floating to horizontal split', function()
            stub(utils, 'is_floating', function() return true end) -- Mock floating window
            nav.bubble_down_h()
            assert.stub(vim.api.nvim_win_close).was_called()
            assert.stub(vim.cmd).was_called_with("split")
            assert.stub(vim.api.nvim_set_current_buf).was_called_with(current_buf)
        end)
    end)

    describe('bubble_down_v', function()
        it('should move buffer from floating to vertical split', function()
            stub(utils, 'is_floating', function() return true end) -- Mock floating window
            nav.bubble_down_v()
            assert.stub(vim.api.nvim_win_close).was_called()
            assert.stub(vim.cmd).was_called_with("vsplit")
            assert.stub(vim.api.nvim_set_current_buf).was_called_with(current_buf)
        end)
    end)

    describe('move_left', function()
        it('should move to the closest left window in the same group', function()
            local new_win = 2
            stub(vim.api, 'nvim_win_get_position', function(win)
                if win == current_win then return { 2, 2 } end
                return { 1, 1 }
            end)
            nav.move_left()
            assert.stub(vim.api.nvim_set_current_win).was_called_with(new_win)
        end)
    end)

    describe('move_right', function()
        it('should move to the closest right window in the same group', function()
            local new_win = 2
            stub(vim.api, 'nvim_win_get_position', function(win)
                if win == current_win then return { 1, 1 } end
                return { 2, 2 }
            end)
            nav.move_right()
            assert.stub(vim.api.nvim_set_current_win).was_called_with(new_win)
        end)
    end)

    describe('move_up', function()
        it('should move to the closest window above in the same group', function()
            local new_win = 2
            stub(vim.api, 'nvim_win_get_position', function(win)
                if win == current_win then return { 2, 2 } end
                return { 1, 1 }
            end)
            nav.move_up()
            assert.stub(vim.api.nvim_set_current_win).was_called_with(new_win)
        end)
    end)

    describe('move_down', function()
        it('should move to the closest window below in the same group', function()
            local new_win = 2
            stub(vim.api, 'nvim_win_get_position', function(win)
                if win == current_win then return { 1, 1 } end
                return { 2, 2 }
            end)
            nav.move_down()
            assert.stub(vim.api.nvim_set_current_win).was_called_with(new_win)
        end)
    end)
end)
