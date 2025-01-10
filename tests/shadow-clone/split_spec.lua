local split = require('shadow-clone.split')
local mock = require('luassert.mock')
local stub = require('luassert.stub')
local manager = require('scmanager')


---@class MockWindow
---@field buf integer
---@field pos integer[]
---@field height integer
---@field width integer

---@class MockNVIMsWindows : table<integer, MockWindow>

---@type MockNVIMsWindows
local windows = {}
local buf_counter = 1
local win_counter = 1
local current_window = -1


describe("split.lua", function()
    before_each(function()
        stub(vim.api, "nvim_get_current_win", function() return current_window end)
        stub(vim.api, "nvim_win_get_buf", function(win) return windows[win].buf end)
        stub(vim.api, "nvim_win_get_position", function(win) return windows[win].pos end)
        stub(vim.api, "nvim_win_get_height", function(win) return windows[win].height end)
        stub(vim.api, "nvim_win_get_width", function(win) return windows[win].width end)
        stub(vim.api, "nvim_win_hide", function(win) windows[win] = nil end)
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
                width = config
                    .width
            }
            if enter then
                current_window = winnr
            end

            return winnr
        end)
        stub(vim.fn, "win_gettype", function(window) return "popup" end)
    end)

    after_each(function()
        windows = {}
        buf_counter = 1
        win_counter = 1
        current_window = -1
        mock.revert(vim.api)
        mock.revert(vim.fn)
        manager.clear()
    end)

    describe("h_split()", function()
        it("should split the floating window horizontally", function()
            windows = {
                [0] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100,
                }
            }

            current_window = 0

            split.h_split()

            local expected = {
                buf = 0,
                pos = { 51, 0 },
                height = 50,
                width = 100,
            }
            assert.are.same(expected, windows[current_window],
                "the split window should be halve the size of the original and located at the midpoint of the original.")
            assert.equals(2, current_window, "after one split the window ID should be 2.")
        end)
    end)

    describe("v_split()", function()
        it("should split the floating window vertically", function()
            windows = {
                [0] = {
                    buf = 0,
                    pos = { 0, 0 },
                    height = 100,
                    width = 100,
                }
            }

            current_window = 0

            split.v_split()

            local expected = {
                buf = 0,
                pos = { 0, 51 },
                height = 100,
                width = 50,
            }
            assert.are.same(expected, windows[current_window],
                "the split window should be halve the size of the original and located at the midpoint of the original.")
            assert.equals(2, current_window, "after one split the window ID should be 2.")
        end)
    end)
end)
