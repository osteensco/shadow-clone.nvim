local manager = require('scmanager')
local mock = require('luassert.mock')
local api = mock(vim.api, true)

describe('manager/internal.lua', function()
    -- used to set clean state before each test
    before_each(function()
        manager.clear()
    end)



    -- Main Stack Operations

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



    -- Hidden Stack Operations

    it('manager.hidden_get_len() should return length of the hidden stack.', function()
        local group = manager.new_group()
        manager.push(group)
        manager.push(group)
        manager.hide_top_group()
        manager.hide_top_group()

        assert.are.same(2, manager.hidden_get_len())
    end)

    it('manager.hidden_toggle_slot_occupied() should accuratley reflect if the toggle slot is occupied or not.',
        function()
            local group = manager.new_group()
            manager.push(group)


            manager.toggle_last_accessed_group()

            assert(manager.hidden_toggle_slot_occupied(), "toggle slot should be occupied after first function call.")
            assert.are.same(vim.inspect({ group }), manager.hidden_inspect().toggle.slot,
                "toggle slot group should be the group we initialized after first function call.")

            manager.toggle_last_accessed_group()

            assert(not manager.hidden_toggle_slot_occupied(),
                "toggle slot should not be occupied after second function call.")
            assert.are.same('{}', manager.hidden_inspect().toggle.slot,
                "toggle slot should not be occupied after second function call.")
        end)

    it('manager.hidden_pop() should pop the top group off the hidden stack.', function()
        local group = manager.new_group()
        manager.push(group)
        manager.hide_top_group()


        grp = manager.hidden_pop()


        assert.are.same(group, grp)
        assert.equals(0, manager.get_len())
        assert.equals(0, manager.hidden_get_len())
    end)

    it('manager.hide_top_group() should remove the top group from the main stack and push it onto the hidden stack.',
        function()
            local group = manager.new_group()
            manager.push(group)


            manager.hide_top_group()


            assert.equals(1, manager.hidden_get_len())
            assert.equals(0, manager.get_len())
        end)

    it(
        'manager.toggle_last_accessed_group() should successfully move a group between the toggle slot and the top of the main stack.',
        function()
            local group = manager.new_group()
            manager.push(group)


            manager.toggle_last_accessed_group()
            assert(manager.hidden_toggle_slot_occupied(), "toggle slot should be occupied after first function call.")

            manager.toggle_last_accessed_group()
            assert(not manager.hidden_toggle_slot_occupied(),
                "toggle slot should not be occupied after second function call.")
        end)




    -- Group Manipulation

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

    it('manager.set_toggle_buffer() should allocate a buffer to a group', function()
        local group = manager.new_group()
        local win1 = { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } }
        local win2 = { bufnr = 3, win = 4, anchor = { x = 10, y = 10 } }

        manager.add_to_group(group, win1)
        manager.add_to_group(group, win2)

        manager.set_toggle_buffer(0, group)
        assert.are.same(manager.get_toggle_buffer(0), group, "The group in toggle buffer 0 should be the one we created.")
    end)

    it('manager.clear_toggle_buffer() should deallocate an allocated toggle buffer', function()
        local group = manager.new_group()
        local win1 = { bufnr = 1, win = 2, anchor = { x = 0, y = 0 } }
        local win2 = { bufnr = 3, win = 4, anchor = { x = 10, y = 10 } }

        manager.add_to_group(group, win1)
        manager.add_to_group(group, win2)

        manager.set_toggle_buffer(0, group)
        manager.clear_toggle_buffer(0)

        local success, res = pcall(manager.get_toggle_buffer, 0)
        assert.is_false(success,
            "This function call should return an error because the buffer should not be allocated. Instead got : " .. res)
    end)
end)

mock.revert(api)
