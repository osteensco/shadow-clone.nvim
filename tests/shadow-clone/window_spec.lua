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

            windows[winnr] = {
                buf = buffer,
                pos = { config.row, config.col },
                height = config.height,
                width = config.width,
                title = config.title
            }
            if enter then
                current_window = winnr
            end

            return winnr
        end)
        stub(vim.api, "nvim_win_get_position", function(winnr) return windows[winnr].pos end)
        stub(vim.api, "nvim_win_hide", function() if win_counter > 0 then win_counter = win_counter - 1 end end)
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
            local key = window.win

            assert.are.same(opts.win_config.title, windows[key].title,
                "The title provided in the config arg should be successfully passed to create_floating_window().")
        end)
    end)

    describe('hide_group()', function()
        it('should successfully hide the group', function()
            local opts = {
                buf = 0,
                row = 0,
                col = 0,
                height = 50,
                width = 50,
            }
            local window1 = win.create_floating_window(opts)
            opts = {
                buf = 0,
                row = 51,
                col = 51,
                height = 50,
                width = 50,
            }
            local window2 = win.create_floating_window(opts)


            local expected = manager.peek()

            win.hide_group()

            assert.are.same(vim.inspect({ expected }), manager.hidden_inspect().stack)
        end)
    end)

    describe('toggle_group()', function()
        it('should successfully toggle the group', function()
            local opts = {
                win_config = {
                    buf = 0,
                    row = 0,
                    col = 0,
                    height = 50,
                    width = 50,
                }
            }
            local window1 = win.create_floating_window(opts)
            opts = {
                win_config = {
                    buf = 0,
                    row = 51,
                    col = 51,
                    height = 50,
                    width = 50,
                }
            }
            local window2 = win.create_floating_window(opts)

            windows = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 50,
                    width = 50,
                },
                [2] = {
                    buf = 0,
                    pos = { 51, 51 },
                    height = 50,
                    width = 50,
                }
            }

            local expected = vim.inspect({ manager.peek() })


            -- first toggle call
            win.toggle_group()

            -- toggle should empty the stack with first call
            assert.equals(0, manager.get_len(), "main stack should be empty after first toggle.")
            -- toggle slot should now be occupied
            assert(manager.hidden_toggle_occupied(),
                "toggle slot should be occupied with group that was originally in the main stack.")


            -- call toggle a second time
            win.toggle_group()

            -- toggle slot should be empty
            assert.equals('{}', manager.hidden_inspect().toggle, "toggle slot should be empty after second toggle.")
            -- main stack should contain 'expected'
            assert.equals(1, manager.get_len(),
                "main stack should be length 1 after second toggle, " ..
                " toggle slot - " .. manager.hidden_inspect().toggle .. ", main stack - " .. manager.inspect())
            assert.equals(expected, manager.inspect(),
                "main stack should contain group captured in 'expected'")
        end)
    end)
end)
