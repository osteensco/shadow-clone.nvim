<h3>What is this?</h3>

<p>
shadow-clone.nvim is a plugin that provides commands and a robust API to manage floating windows on the same level as normal windows in Neovim. This means splitting, controlling the z-index, navigating between floating windows, etc.
The goal is to provide every functionality Neovim provides for normal windows to floating windows, plus some nice additions.
</p>
<br>
<p>
This introduces several problems, which of course is probably why these things aren't available out of the box. To manage floating windows more effectively they are organized into groups. A group represents the z-index of each window in that group. You can navigate between groups, and navigate between windows of a given group with ease.
shadow-clone also provides toggle buffers for you to persist groups, allowing you to predefine a custom group (like terminals, help docs, etc.) and assign it to a toggle buffer. These persist in each session unless explicitly cleared or overwritten. 
</p>
<p>
There is also an ad hoc toggle slot available to use that is cleared after toggle-on.
</p>

<h2></h2>
This is a WIP. See TODO file for specific features I'm working on.

No setup function required, install with your favorite package manager.
```lua
--Lazy
    {
        'osteensco/shadow-clone.nvim',
        dependencies = { "nvim-telescope/telescope.nvim" },
    },

```

You can of course optionally pass your own config to the setup function. More config options to come.
```lua
---defaults
local config = {
    float_window = { -- fields that can be passed to neovim's win_config table on window creation
        position = 'center', 
        width = math.ceil(math.min(vim.o.columns, math.max(80, vim.o.columns - 10))),
        height = math.ceil(math.min(vim.o.lines, math.max(20, vim.o.lines - 5))),
    },
    DEBUG = false,
}

```


<h3>Commands</h3>

 - SCwindow: Creates a new floating window
 - SChide: Hides the current group
 - SCunhidetop: Unhides the last hidden group 
 - SCtoggle: Toggle's the current group (utilizes the toggle slot)
 - SCbubbleup: Move a normal window to a floating window (creates a new group)
 - SCbubbledown: Move a floating window to a normal window (replaces the buffer of last accessed normal window)
 - SCbubbledownh: Move a floating window to a horzontal split of the last accessed normal window
 - SCbubbledownv: Move a floating window to a vertical split of the last accessed normal window
 - SCmoveleft: Move left laterally within the same group
 - SCmoveright: Move right laterally within the same group
 - SCmoveup: Move up laterally within the same group
 - SCmovedown: Move down laterally within the same group
 - SCsplit: Split a floating window horizontally
 - SCvsplit: Split a floating window vertically
 - SCinspect: Prints the contents of shadow-clone's main stack
 - SCinspecthidden: Prints the contents of shadow-clone's hidden data structure (toggle buffers and groups that are in a hidden status)


<h3>API</h3>

```lua
sc = require('shadow-clone')

-- config table that was passed in to the setup function
local sc_config = sc.config

-- optionally call the setup function with your own config
sc.setup(myconfig)

-- inspect shadow-clone's data structure for debugging
print(sc.DEBUG.inspect())
print(sc.DEBUG.inspect_hidden())

-- navigation
sc.navigation.bubble_up()
sc.navigation.bubble_down()
sc.navigation.bubble_down_h()
sc.navigation.bubble_down_v()
sc.navigation.move_left()
sc.navigation.move_right()
sc.navigation.move_up()
sc.navigation.move_down()

-- splitting
sc.split.h_split()
sc.split.v_split()

-- windows and groups
sc.win.new() -- new floating window
sc.win.group.hide() -- hide current group
sc.win.group.unhide(group) -- unhide specified group
sc.win.group.unhidetop() -- unhide last hidden group
sc.win.group.toggle() -- toggle using ad hoc buffer
sc.win.group.togglebuf(bufnr) -- toggle specified toggle buffer
sc.win.group.getcurr() -- retrieve the current group
```

<h3>Keymaps</h3>

These will be adjustable in the future. I will happily take feedback on what the default mappings should be as well.
```lua
vim.api.nvim_set_keymap('n', '<leader>fh', '<cmd>SCmoveleft<CR>', { desc = "Navigate floating window left." })

vim.api.nvim_set_keymap('n', '<leader>fj', '<cmd>SCmovedown<CR>', { desc = "Navigate floating window down." })

vim.api.nvim_set_keymap('n', '<leader>fk', '<cmd>SCmoveup<CR>', { desc = "Navigate floating window up." })

vim.api.nvim_set_keymap('n', '<leader>fl', '<cmd>SCmoveright<CR>', { desc = "Navigate floating window right." })

vim.api.nvim_set_keymap('n', '<leader>fs', '<cmd>SCsplit<CR>',
    { desc = "Split current floating window horizontally." })

vim.api.nvim_set_keymap('n', '<leader>fv', '<cmd>SCvsplit<CR>',
    { desc = "Split current floating window vertically." })

vim.api.nvim_set_keymap('n', '<leader>f,', '<cmd>SChide<CR>',
    { desc = "Hide the current group. Places group in shadow-clone's hidden buffer." })

vim.api.nvim_set_keymap('n', '<leader>f.', '<cmd>SCunhidetop<CR>',
    { desc = "Unhides the last hidden group. Places group at the top of shadow-clone's main stack." })

vim.api.nvim_set_keymap('n', '<leader>ft', '<cmd>SCtoggle<CR>',
    { desc = "Toggle the current group. If a group has already been toggle it will display that group." })
```
