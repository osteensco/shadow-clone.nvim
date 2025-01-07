local win = require('shadow-clone.window')
local manager = require('manager')
local utils = require('shadow-clone.utils')
local mock = require('luassert.mock')

describe('window.create_floating_window', function()
    before_each(function()
        -- Reset mock functions or any state if necessary
        -- mock(manager, "new_group", function() return { members = {}, zindex = 0 } end)
        -- mock(manager, "pop", function() return {} end)
        -- mock(manager, "add_to_group", function(group, window) end)
        -- mock(manager, "push", function(group) end)
        mock(utils, "get_pos", function() return { x = 10, y = 20 } end)
        mock(vim.api, "nvim_buf_is_valid", function() return true end)
        mock(vim.api, "nvim_create_buf", function() return 1 end)
        mock(vim.api, "nvim_open_win", function() return 1 end)
        mock(vim.api, "nvim_win_get_position", function() return { 10, 20 } end)
        mock(vim.api, "nvim_win_set_config", function() end)
        manager.clear()
    end)

    after_each(function()
        -- Restore any mocked functions or states
        -- mock.revert(manager)
        mock.revert(utils)
        mock.revert(vim.api)
    end)

    it('should create a floating window that is accessible in the stack\'s only group.', function()
        local window = win.create_floating_window()
        local result = manager.peek()

        assert.equals(1, manager.get_len())
        assert.are.same(window, result.members[1])
    end)

    it('should apply the provided buffer to the new window correctly', function()
        local opts = { buf = 5 }
        local window = win.create_floating_window(opts)
        local result = manager.peek()

        assert.equal(5, window.bufnr, "Bufnr should be 5.")
        assert.equal(1, window.win, "Window ID should be 1.") -- this fails because we aren't mocking correctly

        assert.equals(1, manager.get_len(), "Length of the manager's stack should be 1.")
        assert.are.same(window, result.members[1],
            "The only window in the only group of the stack should be the one we created.")
    end)

    it('should create a new group if no existing group is available', function()
        local opts = { newgroup = true }
        local window = win.create_floating_window(opts)

        -- Check if new group creation was triggered
        assert.has_called(manager.new_group)
        assert.has_called(manager.push)
    end)

    it('should use an existing group if newgroup is false', function()
        local opts = { newgroup = false }
        local existing_group = { members = {}, zindex = 0 }
        mock(manager, "pop", function() return existing_group end)

        local window = win.create_floating_window(opts)

        -- Check if existing group was used
        assert.has_called_with(manager.push, existing_group, window)
    end)

    it('should set correct window configuration after creation', function()
        local opts = { win_config = { title = "Test Window" } }
        local window = win.create_floating_window(opts)

        -- Check if window config was correctly applied
        assert.has_called_with(vim.api.nvim_win_set_config, window.win, {
            title = "group: 0 win: 1 - x: 10, y: 20",
            title_pos = "center"
        })
    end)
end)
