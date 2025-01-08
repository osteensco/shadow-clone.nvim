local manager = require('manager')
local mock = require('luassert.mock')
local api = mock(vim.api, true)

describe('Manager Module - ', function()
    -- used to set clean state before each test
    before_each(function()
        manager.clear()
    end)

    it('manager.push() should push a new group with the correct zindex', function()
        local group = manager.new_group()

        manager.push(group)


        assert.are.same(manager.get_len(), 1)
        assert.are.same(group.zindex, 1)
    end)

    it('manager.peek() should peek the top group without removing it', function()
        local group1 = manager.new_group()
        manager.push(group1)

        local group2 = manager.new_group()
        manager.push(group2)

        local top_group = manager.peek()

        assert.are.same(top_group, group2)
        assert.are.same(manager.get_len(), 2)
    end)

    it('manager.pop() should pop the top group', function()
        local group1 = manager.new_group()
        manager.push(group1)

        local group2 = manager.new_group()
        manager.push(group2)

        local popped_group = manager.pop()

        assert.are.same(manager.get_len(), 1)
        assert.are.same(popped_group, group2)
    end)


    it('manager.swap() should swap the top two groups', function()
        local group1 = manager.new_group()
        local win1 = { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } }
        manager.push(group1)
        manager.add_to_group(group1, win1)

        local group2 = manager.new_group()
        local win2 = { bufnr = 3, win = 4, anchor = { x = 10, y = 10 } }
        manager.push(group2)
        manager.add_to_group(group2, win2)

        manager.swap()

        local stack = { group2, group1 }
        assert.are.same(manager.inspect(), vim.inspect(stack))
    end)

    it('manager.cycle() should cycle a group to the bottom of the stack and adjust zindex', function()
        local group1 = manager.new_group()
        local win1 = { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } }
        manager.push(group1)
        manager.add_to_group(group1, win1)

        local group2 = manager.new_group()
        local win2 = { bufnr = 3, win = 4, anchor = { x = 10, y = 10 } }
        manager.push(group2)
        manager.add_to_group(group2, win2)

        local group3 = manager.new_group()
        local win3 = { bufnr = 5, win = 6, anchor = { x = 20, y = 20 } }
        manager.push(group3)
        manager.add_to_group(group3, win3)

        manager.cycle()

        local stack = { group3, group1, group2 }
        assert.are.same(manager.inspect(), vim.inspect(stack))
    end)

    it('manager.add_to_group() should add a window to a group', function()
        local group = manager.new_group()
        local win = { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } }

        manager.add_to_group(group, win)

        assert.are.same(#group.members, 1)
        assert.are.same(group.members[1], win)
    end)

    it('manager.remove_from_group() should remove a window from a group', function()
        local group = manager.new_group()
        local win1 = { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } }
        local win2 = { bufnr = 3, win = 4, anchor = { x = 10, y = 10 } }

        manager.add_to_group(group, win1)
        manager.add_to_group(group, win2)

        manager.remove_from_group(group, win1)

        assert.are.same(#group.members, 1)
        assert.are.same(group.members[1], win2)
    end)
end)

mock.revert(api)
