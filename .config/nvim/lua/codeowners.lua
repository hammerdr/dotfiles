local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<leader>co', '<cmd>CodeownersWhoOwns<CR>', opts)
vim.keymap.set('n', '<leader>cw', '<cmd>CodeownersGotoTeamDefinition<CR>', opts)
vim.keymap.set('n', '<leader>cH', '<cmd>CodeownersGotoTeamHelpChannel<CR>', opts)
