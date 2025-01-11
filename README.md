WIP. See TODO file for implemented features thus far.

No setup function required, install with your favorite package manager.

A config table can be passed to the setup function.
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
