local win = require('shadow-clone.window')
local nav = require('shadow-clone.navigation')
local split = require('shadow-clone.split')
local picker = require('shadow-clone.pickers')

local cmds = {}

cmds.init = function()
    -- commands

    -- window/group management
    vim.api.nvim_create_user_command("SCwindow", win.create_floating_window, { nargs = '?' })
    vim.api.nvim_create_user_command("SChide", win.hide_group, { nargs = 0 })
    vim.api.nvim_create_user_command("SCunhide", picker.hidden_windows, { nargs = 0 })
    vim.api.nvim_create_user_command("SCunhidetop", win.unhide_top, { nargs = 0 })
    vim.api.nvim_create_user_command("SCtoggle", win.toggle_group, { nargs = 0 })

    -- navigations
    vim.api.nvim_create_user_command("SCbubbleup", nav.bubble_up, { nargs = 0 })
    vim.api.nvim_create_user_command("SCbubbledown", nav.bubble_down, { nargs = 0 })
    vim.api.nvim_create_user_command("SCbubbledownh", nav.bubble_down_h, { nargs = 0 })
    vim.api.nvim_create_user_command("SCbubbledownv", nav.bubble_down_v, { nargs = 0 })
    vim.api.nvim_create_user_command("SCmoveleft", nav.move_left, { nargs = 0 })
    vim.api.nvim_create_user_command("SCmoveright", nav.move_right, { nargs = 0 })
    vim.api.nvim_create_user_command("SCmoveup", nav.move_up, { nargs = 0 })
    vim.api.nvim_create_user_command("SCmovedown", nav.move_down, { nargs = 0 })

    -- splits
    vim.api.nvim_create_user_command("SCsplit", split.h_split, { nargs = '?' })
    vim.api.nvim_create_user_command("SCvsplit", split.v_split, { nargs = '?' })

    -- debug
    vim.api.nvim_create_user_command("SCinspect", function()
        print(require('shadow-clone.utils').inspect())
    end, { nargs = 0 })
    vim.api.nvim_create_user_command("SCinspecthidden", function()
        local hidden = require('shadow-clone.utils').inspect_hidden()
        print("hidden.stack: " .. hidden.stack)
        print("hidden.toggle: " .. hidden.toggle)
    end, { nargs = 0 })
end

return cmds
