describe("split.lua", function()
    local split
    local mock_utils
    local mock_window
    local mock_manager
    local mock_vim

    -- Mocking Neovim API calls
    before_each(function()
        mock_utils = require('shadow-clone.utils')
    end)

    describe("horizontal split", function()
        it("should split the floating window horizontally", function()
            -- Mock necessary Vim API functions
            mock_utils.is_floating = function() return true end
            mock_vim.api.nvim_get_current_win = function() return 1 end
            mock_vim.api.nvim_win_get_buf = function() return 1 end
            mock_vim.api.nvim_win_get_position = function() return { 1, 1 } end
            mock_vim.api.nvim_win_get_height = function() return 20 end
            mock_vim.api.nvim_win_get_width = function() return 40 end
            mock_manager.peek = function() return {} end

            -- Call the function
            split.h_split()

            -- Assert that two floating windows are created with the correct properties
            assert.are.equal(mock_vim.api.nvim_win_get_height(1), 10)
            assert.are.equal(mock_vim.api.nvim_win_get_width(1), 40)
            -- Add more assertions to check window positions
        end)

        it("should not split if the current window is not floating", function()
            -- Mock that the window is not floating
            mock_utils.is_floating = function() return false end

            -- Call the function
            split.h_split()

            -- Assert that no new windows were created
            assert.spy(mock_vim.api.nvim_open_win).was_not_called()
        end)
    end)

    describe("vertical split", function()
        it("should split the floating window vertically", function()
            -- Mock necessary Vim API functions
            mock_utils.is_floating = function() return true end
            mock_vim.api.nvim_get_current_win = function() return 1 end
            mock_vim.api.nvim_win_get_buf = function() return 1 end
            mock_vim.api.nvim_win_get_position = function() return { 1, 1 } end
            mock_vim.api.nvim_win_get_height = function() return 20 end
            mock_vim.api.nvim_win_get_width = function() return 40 end
            mock_manager.peek = function() return {} end

            -- Call the function
            split.v_split()

            -- Assert that two floating windows are created with the correct properties
            assert.are.equal(mock_vim.api.nvim_win_get_height(1), 20)
            assert.are.equal(mock_vim.api.nvim_win_get_width(1), 20)
            -- Add more assertions to check window positions
        end)

        it("should not split if the current window is not floating", function()
            -- Mock that the window is not floating
            mock_utils.is_floating = function() return false end

            -- Call the function
            split.v_split()

            -- Assert that no new windows were created
            assert.spy(mock_vim.api.nvim_open_win).was_not_called()
        end)
    end)

    describe("when the group is empty", function()
        it("should handle empty groups correctly", function()
            -- Mock that there are no windows in the group
            mock_manager.peek = function() return {} end

            -- Call the split function
            split.h_split()

            -- Ensure that it doesn't attempt to remove anything from the group
            assert.spy(mock_manager.remove_from_group).was_not_called()
        end)
    end)
end)
