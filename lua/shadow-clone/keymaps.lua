local keymaps = {}

keymaps.init = function()
    vim.api.nvim_set_keymap('n', '<leader>fh', '<cmd>SCmoveleft<CR>', { desc = "Navigate floating window left." })
    vim.api.nvim_set_keymap('n', '<leader>fj', '<cmd>SCmovedown<CR>', { desc = "Navigate floating window down." })
    vim.api.nvim_set_keymap('n', '<leader>fk', '<cmd>SCmoveup<CR>', { desc = "Navigate floating window up." })
    vim.api.nvim_set_keymap('n', '<leader>fl', '<cmd>SCmoveright<CR>', { desc = "Navigate floating window right." })

    vim.api.nvim_set_keymap('n', '<leader>fs', '<cmd>SCsplit<CR>',
        { desc = "Split current floating window horizontally." })
    vim.api.nvim_set_keymap('n', '<leader>fv', '<cmd>SCvsplit<CR>',
        { desc = "Split current floating window vertically." })
end

return keymaps
