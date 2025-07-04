local telescope = require('telescope')

telescope.setup {
  defaults = {
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case'
    },
  },
  pickers = {
    git_commits = {
      theme = "dropdown",
    },
    git_branches = {
      theme = "dropdown",
    },
    git_status = {
      theme = "dropdown",
    },
  },
}

telescope.load_extension('fzf')
telescope.load_extension('lsp_handlers')

local builtin = require('telescope.builtin')
local code_review = require('code_review')

-- File navigation
vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<C-p>', builtin.find_files, { desc = 'Find files' })
vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Live grep' })
vim.keymap.set('n', '<leader>fG', builtin.grep_string, { desc = 'Grep string under cursor' })
vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })

-- Git integration
vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = 'Git commits' })
vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Git branches' })
vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = 'Git status' })
vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Git files' })

-- Code review keymaps
vim.keymap.set('n', '<leader>gr', code_review.review_changes, { desc = 'Review git changes' })
vim.keymap.set('n', '<leader>gR', code_review.review_commits, { desc = 'Review commits' })
vim.keymap.set('n', '<leader>gd', function() code_review.review_branch_diff({ base = 'main' }) end, { desc = 'Review branch diff with main' })
vim.keymap.set('n', '<leader>gD', function() 
    vim.ui.input({ prompt = 'Base branch: ', default = 'main' }, function(input)
        if input then
            code_review.review_branch_diff({ base = input })
        end
    end)
end, { desc = 'Review branch diff with custom base' })

function FindIn(search_dir)
  require('telescope.builtin').live_grep({default_text = " ", search_dirs = { search_dir }})
end

vim.api.nvim_create_user_command('FindIn', 'lua FindIn(<q-args>)', { nargs = 1, complete = "file" })
