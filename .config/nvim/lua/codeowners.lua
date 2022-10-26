local opts = { noremap=true, silent=true }
vim.api.nvim_set_keymap('n', '<leader>co', '<cmd>CodeownersWhoOwns<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>ct', '<cmd>CodeownersGotoTeamDefinition<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>ch', '<cmd>CodeownersGotoTeamHelpChannel<CR>', opts)
