require('telescope').setup {}
require('telescope').load_extension('fzf')
require('telescope').load_extension('lsp_handlers')

local opts = { noremap=true, silent=true }
vim.api.nvim_set_keymap('n', '<leader>ff', '<cmd>Telescope find_files<CR>', opts)
vim.api.nvim_set_keymap('n', '<C-p>', '<cmd>Telescope find_files<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>fg', '<cmd>Telescope live_grep<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>fG', '<cmd>Telescope grep_string<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>fb', '<cmd>Telescope buffers<CR>', opts)
vim.api.nvim_set_keymap('n', '<leader>fh', '<cmd>Telescope help_tags<CR>', opts)

function FindIn(search_dir)
  require('telescope.builtin').live_grep({default_text = " ", search_dirs = { search_dir }})
end

vim.api.nvim_create_user_command('FindIn', 'lua FindIn(<q-args>)', { nargs = 1, complete = "file" })
