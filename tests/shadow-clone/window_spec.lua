local win = require('shadow-clone.window')
local manager = require('scmanager')
local utils = require('shadow-clone.utils')
local mock = require('luassert.mock')
local stub = require('luassert.stub')

local windows = {}
local buf_counter = 1
local win_counter = 1

describe('window.lua', function()
    before_each(function()
        windows = {}
        buf_counter = 1
        win_counter = 1
        stub(utils, "get_pos", function() return { x = 10, y = 20 } end)
        stub(vim.api, "nvim_buf_is_valid", function() return true end)
        stub(vim.api, "nvim_create_buf", function()
            local bufnr = buf_counter
            buf_counter = bufnr + 1
            return bufnr
        end)
        stub(vim.api, "nvim_open_win", function(buffer, enter, config)
            local winnr = win_counter
            win_counter = winnr + 1

            local key = "win_" .. winnr
            windows[key] = config

            return winnr
        end)
        stub(vim.api, "nvim_win_get_position", function() return { 10, 20 } end)
        manager.clear()
    end)

    after_each(function()
        mock.revert(vim.api)
    end)

    describe('create_floating_window()', function()
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
            assert.equal(1, window.win, "Window ID should be 1.")

            assert.equals(1, manager.get_len(), "Length of the manager's stack should be 1.")
            assert.are.same(window, result.members[1],
                "The only window in the only group of the stack should be the one we created.")
        end)

        it('should create a new group if no existing group is available', function()
            local opts = { newgroup = true }
            local existing_group = { members = {}, zindex = 0 }
            manager.push(existing_group)
            local window = win.create_floating_window(opts)
            local result = manager.peek()

            assert.equals(2, manager.get_len(), "Length of the manager's stack should be 2.")
            assert.are.same(window, result.members[1],
                "The only window in group from the top of the stack should be the one we created.")
        end)

        it('should use an existing group if newgroup is false', function()
            local opts = { newgroup = false }
            local existing_group = { members = {}, zindex = 0 }
            manager.push(existing_group)
            local result = manager.peek()

            assert.equals(0, #result.members,
                "Length of the group from the top of the stack should be 0 before we create a window.")

            local window = win.create_floating_window(opts)
            result = manager.peek()

            assert.equals(1, manager.get_len(), "Length of the manager's stack should be 1.")
            assert.are.same(window, result.members[1],
                "The only window in the only group of the stack should be the one we created.")
            assert.equals(1, #result.members,
                "Length of the group from the top of the stack should be 1 after we create a window.")
        end)

        it('should set correct window configuration after creation', function()
            local opts = { win_config = { title = "Test Window" } }
            local window = win.create_floating_window(opts)
            local key = "win_" .. window.win

            assert.are.same(opts.win_config.title, windows[key].title,
                "The title provided in the config arg should be successfully passed to create_floating_window().")
        end)
    end)
end)
