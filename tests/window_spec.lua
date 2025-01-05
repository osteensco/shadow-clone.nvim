local helpers = require("plenary.test_harness")
local window = require("manager.window")

describe("Window Module", function()
    it("should create a floating window", function()
        local win = window.create_floating({ width = 20, height = 10 })
        assert.is_true(vim.api.nvim_win_is_valid(win), "Floating window is invalid")
    end)

    it("should fail gracefully with invalid dimensions", function()
        assert.has_error(function()
            window.create_floating({ width = -1, height = 10 })
        end, "Did not throw error for invalid dimensions")
    end)

    it("should resize a window correctly", function()
        local win = window.create_floating({ width = 20, height = 10 })
        window.resize(win, { width = 30, height = 15 })
        local config = vim.api.nvim_win_get_config(win)
        assert.are.equal(30, config.width, "Width was not resized correctly")
        assert.are.equal(15, config.height, "Height was not resized correctly")
    end)

    it("should close a window successfully", function()
        local win = window.create_floating({ width = 20, height = 10 })
        window.close(win)
        assert.is_false(vim.api.nvim_win_is_valid(win), "Window was not closed")
    end)
end)
