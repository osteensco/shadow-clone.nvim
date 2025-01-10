local nav = require('shadow-clone.navigation')
local utils = require('shadow-clone.utils')
local _win = require('shadow-clone.window')
local manager = require('scmanager')
local mock = require('luassert.mock')
local stub = require('luassert.stub')


---@class MockWindow
---@field buf integer
---@field pos integer[]
---@field height integer
---@field width integer

---@class MockNVIMsWindows : table<integer, MockWindow>


local current_win = 1
local current_buf = 2
local buf_counter = 1
local win_counter = 1


---@type MockNVIMsWindows
local float_wins = {}
---@type MockNVIMsWindows
local normal_wins = {}



describe('navigation.lua', function()
    before_each(function()
        stub(utils, 'is_floating', function() return true end)

        stub(vim.fn, 'winnr', function() return 2 end)

        stub(vim.api, 'nvim_buf_is_valid', function(bufnr) return true end)
        stub(vim.api, "nvim_create_buf", function()
            local bufnr = buf_counter
            buf_counter = bufnr + 1
            return bufnr
        end)
        stub(vim.api, "nvim_open_win", function(buffer, enter, config)
            local winnr = win_counter
            win_counter = winnr + 1

            float_wins[winnr] = config
            float_wins[winnr].buf = buffer

            if enter then
                current_window = winnr
            end

            return winnr
        end)

        stub(vim.api, 'nvim_get_current_win', function() return current_win end)
        stub(vim.api, 'nvim_set_current_win', function(win) current_win = win end)
        stub(vim.api, 'nvim_win_get_position', function(win)
            if utils.is_floating(win) then
                return { float_wins[win].row, float_wins[win].col }
            else
                return { normal_wins[win].row, normal_wins[win].col }
            end
        end) -- this is breaking tests
        stub(vim.api, 'nvim_win_get_height', function() return 100 end)
        stub(vim.api, 'nvim_win_get_width', function() return 100 end)
        stub(vim.api, 'nvim_win_close', function() current_win = current_win - 1 end)
        stub(vim.api, 'nvim_set_current_buf', function(bufnr) normal_wins[current_win].buf = bufnr end)

        mock(vim.cmd, function(split_type)
            if split_type == 'split' then
                -- add two normal windows split horizontally
            elseif split_type == 'vsplit' then
                -- add two normal windows split vertically
            end
        end)
    end)

    after_each(function()
        manager.clear()
        normal_wins = {}
        float_wins = {}
        current_win = 1
        current_buf = 1
        buf_counter = 1
        win_counter = 1
        mock.revert(vim.api)
        mock.revert(vim.fn)
        mock.revert(utils)
        mock.revert(vim.cmd)
    end)

    -- bubble functions care about:
    --  - adding and removing from the stack
    --  - transfering the current buffer successfully
    describe('bubble_up()', function()
        it('should move buffer to a floating window', function()
            stub(utils, 'is_floating', function() return false end)
            normal_wins = {
                [1] = {
                    buf = 2,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100
                },
            }

            nav.bubble_up()

            assert.equals(1, manager.get_len())
            local grp = manager.peek()
            assert.equals(1, #grp.members)
            assert.equals(float_wins[1].buf, grp.members[1].bufnr)
        end)
    end)

    describe('bubble_down()', function()
        it('should move buffer from floating to normal window', function()
            manager.push({ members = { { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } } }, zindex = 1 })
            float_wins = {
                [2] = {
                    buf = 1,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100
                },
            }
            normal_wins = {
                [1] = {
                    buf = 2,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100
                },
            }

            current_win = 2
            -- show original buffer in normal window is different than final result
            assert.equals(2, normal_wins[1].buf, "Check initialized state, bufnr should be 2.")

            nav.bubble_down()


            assert.equals(0, manager.get_len(),
                "len of stack should be 0 after bubble_down call because an empty group would trigger a pop() operation.  - " ..
                manager.inspect())
            assert.equals(nil, normal_wins[2], "the number of normal windows should remain at 1.")
            assert.equals(1, normal_wins[1].buf,
                "the buffer in the normal window should be that of the original floating window (1). current_win: " ..
                vim.inspect(normal_wins[current_win]))
        end)
    end)

    describe('bubble_down_h()', function()
        it('should move buffer from floating to horizontal split', function()
            current_win = 2
            manager.push({ members = { { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } } }, zindex = 1 })
            float_wins = {
                [2] = {
                    buf = 1,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100
                },
            }
            normal_wins = {
                [1] = {
                    buf = 2,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100
                },
            }

            -- show original buffer in normal window is different than final result
            assert.equals(2, normal_wins[1].buf, "Check initialized state, bufnr should be 2.")
            assert.equals(1, manager.get_len(), "manager's initial state should have 1 group with 1 window.")

            nav.bubble_down_h()


            assert.equals(0, manager.get_len(),
                "len of stack should be 0 after bubble_down call because an empty group would trigger a pop() operation.  - " ..
                manager.inspect())
            assert.equals(nil, normal_wins[2], "the number of normal windows should remain at 1.")
            assert.equals(1, normal_wins[1].buf,
                "the buffer in the normal window should be that of the original floating window (1). current_win: " ..
                vim.inspect(normal_wins[current_win]))
        end)
    end)

    describe('bubble_down_v()', function()
        it('should move buffer from floating to vertical split', function()
            current_win = 2
            manager.push({ members = { { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } } }, zindex = 1 })
            float_wins = {
                [2] = {
                    buf = 1,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100
                },
            }
            normal_wins = {
                [1] = {
                    buf = 2,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100
                },
            }

            -- show original buffer in normal window is different than final result
            assert.equals(2, normal_wins[1].buf, "Check initialized state, bufnr should be 2.")
            assert.equals(1, manager.get_len(), "manager's initial state should have 1 group with 1 window.")

            nav.bubble_down_v()


            assert.equals(0, manager.get_len(),
                "len of stack should be 0 after bubble_down call because an empty group would trigger a pop() operation.  - " ..
                manager.inspect())
            assert.equals(nil, normal_wins[2], "the number of normal windows should remain at 1.")
            assert.equals(1, normal_wins[1].buf,
                "the buffer in the normal window should be that of the original floating window (1). current_win: " ..
                vim.inspect(normal_wins[current_win]))
        end)
    end)


    -- movement functions really only care about window anchor points
    describe('move_left()', function()
        it('should move to the closest left window in the same group', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 50,
                    width = 10,
                },
                [2] = {
                    buf = 0,
                    pos = { 0, 12 },
                    height = 50,
                    width = 10,
                },
                [3] = {
                    buf = 0,
                    pos = { 0, 24 },
                    height = 50,
                    width = 10,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 3
            nav.move_left()

            assert.equals(2, current_win,
                "starting at window 3, current window should move left to window 2. -> " .. manager.inspect())
        end)

        it('should move to the farthest right window in the same group if currently in the leftmost window', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 50,
                    width = 10,
                },
                [2] = {
                    buf = 0,
                    pos = { 0, 12 },
                    height = 50,
                    width = 10,
                },
                [3] = {
                    buf = 0,
                    pos = { 0, 24 },
                    height = 50,
                    width = 10,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 1
            nav.move_left()

            assert.equals(3, current_win,
                "starting at window 1, current window should wrap around to window 3. -> " .. manager.inspect())
        end)

        it('should move left successfully more than once', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 50,
                    width = 10,
                },
                [2] = {
                    buf = 0,
                    pos = { 0, 12 },
                    height = 50,
                    width = 10,
                },
                [3] = {
                    buf = 0,
                    pos = { 0, 24 },
                    height = 50,
                    width = 10,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 3
            nav.move_left()

            assert.equals(2, current_win,
                "starting at window 3, current window should move left to window 2 after 1st call. -> " ..
                manager.inspect())

            nav.move_left()
            assert.equals(1, current_win,
                "starting at window 3, current window should move left to window 1 after 2nd call. -> " ..
                manager.inspect())

            nav.move_left()
            assert.equals(3, current_win,
                "starting at window 3, current window should wrap around to window 3 after 3rd call. -> " ..
                manager.inspect())
        end)
    end)

    describe('move_right()', function()
        it('should move to the closest right window in the same group', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 50,
                    width = 10,
                },
                [2] = {
                    buf = 0,
                    pos = { 0, 12 },
                    height = 50,
                    width = 10,
                },
                [3] = {
                    buf = 0,
                    pos = { 0, 24 },
                    height = 50,
                    width = 10,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 1
            nav.move_right()

            assert.equals(2, current_win,
                "starting at window 1, current window should move right to window 2. -> " .. manager.inspect())
        end)

        it('should move to the farthest left window in the same group if currently in the rightmost window', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 50,
                    width = 10,
                },
                [2] = {
                    buf = 0,
                    pos = { 0, 12 },
                    height = 50,
                    width = 10,
                },
                [3] = {
                    buf = 0,
                    pos = { 0, 24 },
                    height = 50,
                    width = 10,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 3
            nav.move_right()

            assert.equals(1, current_win,
                "starting at window 3, current window should wrap around to window 1. -> " .. manager.inspect())
        end)

        it('should move right successfully more than once', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 50,
                    width = 10,
                },
                [2] = {
                    buf = 0,
                    pos = { 0, 12 },
                    height = 50,
                    width = 10,
                },
                [3] = {
                    buf = 0,
                    pos = { 0, 24 },
                    height = 50,
                    width = 10,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 1
            nav.move_right()

            assert.equals(2, current_win,
                "starting at window 1, current window should move right to window 2 after 1st call. -> " ..
                manager.inspect())

            nav.move_right()
            assert.equals(3, current_win,
                "starting at window 1, current window should move right to window 3 after 2nd call. -> " ..
                manager.inspect())

            nav.move_right()
            assert.equals(1, current_win,
                "starting at window 1, current window should wrap around to window 1 after 3rd call. -> " ..
                manager.inspect())
        end)
    end)

    describe('move_up()', function()
        it('should move to the closest window above the current one in the same group', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 10,
                    width = 50,
                },
                [2] = {
                    buf = 0,
                    pos = { 12, 0 },
                    height = 10,
                    width = 50,
                },
                [3] = {
                    buf = 0,
                    pos = { 24, 0 },
                    height = 10,
                    width = 50,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 3
            nav.move_up()

            assert.equals(2, current_win,
                "starting at window 3, current window should move up to window 2. -> " .. manager.inspect())
        end)

        it('should move to the bottom window in the same group if currently in the top window', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 10,
                    width = 50,
                },
                [2] = {
                    buf = 0,
                    pos = { 12, 0 },
                    height = 10,
                    width = 50,
                },
                [3] = {
                    buf = 0,
                    pos = { 24, 0 },
                    height = 10,
                    width = 50,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 1
            nav.move_up()

            assert.equals(3, current_win,
                "starting at window 1, current window should wrap around to window 3. -> " .. manager.inspect())
        end)

        it('should move up successfully more than once', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 10,
                    width = 50,
                },
                [2] = {
                    buf = 0,
                    pos = { 12, 0 },
                    height = 10,
                    width = 50,
                },
                [3] = {
                    buf = 0,
                    pos = { 24, 0 },
                    height = 10,
                    width = 50,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 3
            nav.move_up()

            assert.equals(2, current_win,
                "starting at window 3, current window should move up to window 2 after 1st call. -> " ..
                manager.inspect())

            nav.move_up()
            assert.equals(1, current_win,
                "starting at window 3, current window should move up to window 1 after 2nd call. -> " ..
                manager.inspect())

            nav.move_up()
            assert.equals(3, current_win,
                "starting at window 3, current window should wrap around to window 3 after 3rd call. -> " ..
                manager.inspect())
        end)
    end)

    describe('move_down()', function()
        it('should move to the closest window below the current one in the same group', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 10,
                    width = 50,
                },
                [2] = {
                    buf = 0,
                    pos = { 12, 0 },
                    height = 10,
                    width = 50,
                },
                [3] = {
                    buf = 0,
                    pos = { 24, 0 },
                    height = 10,
                    width = 50,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 1
            nav.move_down()

            assert.equals(2, current_win,
                "starting at window 1, current window should move down to window 2. -> " .. manager.inspect())
        end)

        it('should move to the top window in the same group if currently in the bottom window', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 10,
                    width = 50,
                },
                [2] = {
                    buf = 0,
                    pos = { 12, 0 },
                    height = 10,
                    width = 50,
                },
                [3] = {
                    buf = 0,
                    pos = { 24, 0 },
                    height = 10,
                    width = 50,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 3
            nav.move_down()

            assert.equals(1, current_win,
                "starting at window 3, current window should wrap around to window 1. -> " .. manager.inspect())
        end)

        it('should move down successfully more than once', function()
            float_wins = {
                [1] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 10,
                    width = 50,
                },
                [2] = {
                    buf = 0,
                    pos = { 12, 0 },
                    height = 10,
                    width = 50,
                },
                [3] = {
                    buf = 0,
                    pos = { 24, 0 },
                    height = 10,
                    width = 50,
                }
            }

            local grp = manager.new_group()
            for _, window in ipairs(float_wins) do
                _win.create_floating_window({
                    buf = window.buf,
                    win_config = {
                        height = window.height,
                        width = window.width,
                        row = window.pos[1],
                        col = window.pos[2]
                    },
                    newgroup = false
                })
            end

            current_win = 1
            nav.move_down()

            assert.equals(2, current_win,
                "starting at window 1, current window should move down to window 2 after 1st call. -> " ..
                manager.inspect())

            nav.move_down()
            assert.equals(3, current_win,
                "starting at window 1, current window should move down to window 3 after 2nd call. -> " ..
                manager.inspect())

            nav.move_down()
            assert.equals(1, current_win,
                "starting at window 1, current window should wrap around to window 1 after 3rd call. -> " ..
                manager.inspect())
        end)
    end)
end)
