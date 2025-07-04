require('telescope').setup {}
require('telescope').load_extension('fzf')
require('telescope').load_extension('lsp_handlers')

local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fG', builtin.grep_string, { desc = 'Grep string under cursor' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })

function FindIn(search_dir)
  require('telescope.builtin').live_grep({default_text = " ", search_dirs = { search_dir }})
end

vim.api.nvim_create_user_command('FindIn', 'lua FindIn(<q-args>)', { nargs = 1, complete = "file" })
