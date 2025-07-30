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
vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = 'Help tags' })

-- Enhanced buffer management
vim.keymap.set('n', '<leader>fb', function()
  builtin.buffers({
    show_all_buffers = true,
    sort_mru = true,
    ignore_current_buffer = false,
    previewer = false,
    theme = "dropdown",
    layout_config = {
      height = 0.4,
      width = 0.8,
    }
  })
end, { desc = 'Find buffers' })

vim.keymap.set('n', '<C-b>', function()
  builtin.buffers({
    show_all_buffers = true,
    sort_mru = true,
    ignore_current_buffer = true,
    previewer = false,
    theme = "dropdown"
  })
end, { desc = 'Switch buffers' })

-- Recent files
vim.keymap.set('n', '<leader>fr', builtin.oldfiles, { desc = 'Recent files' })

-- Git integration
vim.keymap.set('n', '<leader>gc', builtin.git_commits, { desc = 'Git commits' })
vim.keymap.set('n', '<leader>gb', builtin.git_branches, { desc = 'Git branches' })
vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = 'Git status' })
vim.keymap.set('n', '<leader>gf', builtin.git_files, { desc = 'Git files' })

-- Enhanced git integrations for changed files
vim.keymap.set('n', '<leader>gm', function()
  builtin.git_status({ 
    git_icons = {
      added = "A",
      changed = "M",
      copied = "C",
      deleted = "D",
      renamed = "R",
      unmerged = "U",
      untracked = "?",
    }
  })
end, { desc = 'Git modified files' })

vim.keymap.set('n', '<leader>gS', function()
  builtin.git_stash()
end, { desc = 'Git stash' })

-- Quick access to changed files in current branch vs main
vim.keymap.set('n', '<leader>gC', function()
  builtin.git_commits({
    git_command = { "git", "log", "--oneline", "--decorate", "--all", "--graph" }
  })
end, { desc = 'Git commits (graph)' })

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

-- LSP integrations
vim.keymap.set('n', '<leader>lr', builtin.lsp_references, { desc = 'LSP references' })
vim.keymap.set('n', '<leader>ld', builtin.lsp_definitions, { desc = 'LSP definitions' })
vim.keymap.set('n', '<leader>li', builtin.lsp_implementations, { desc = 'LSP implementations' })
vim.keymap.set('n', '<leader>lt', builtin.lsp_type_definitions, { desc = 'LSP type definitions' })
vim.keymap.set('n', '<leader>ls', builtin.lsp_document_symbols, { desc = 'LSP document symbols' })
vim.keymap.set('n', '<leader>lS', builtin.lsp_workspace_symbols, { desc = 'LSP workspace symbols' })
vim.keymap.set('n', '<leader>le', builtin.diagnostics, { desc = 'LSP diagnostics' })

-- Treesitter integrations
vim.keymap.set('n', '<leader>ts', builtin.treesitter, { desc = 'Treesitter symbols' })

-- Trouble.nvim integration
vim.keymap.set('n', '<leader>tt', function()
  require('trouble').toggle()
end, { desc = 'Toggle Trouble' })

vim.keymap.set('n', '<leader>tw', function()
  require('trouble').toggle('workspace_diagnostics')
end, { desc = 'Trouble workspace diagnostics' })

vim.keymap.set('n', '<leader>td', function()
  require('trouble').toggle('document_diagnostics')
end, { desc = 'Trouble document diagnostics' })

-- Vim-fugitive enhanced integrations
vim.keymap.set('n', '<leader>gB', function()
  vim.cmd('Git blame')
end, { desc = 'Git blame' })

vim.keymap.set('n', '<leader>gL', function()
  vim.cmd('Git log --oneline')
end, { desc = 'Git log' })

vim.keymap.set('n', '<leader>gP', function()
  vim.cmd('Git push')
end, { desc = 'Git push' })

vim.keymap.set('n', '<leader>gp', function()
  vim.cmd('Git pull')
end, { desc = 'Git pull' })

-- Quick access to commonly used telescope pickers
vim.keymap.set('n', '<leader>:', builtin.command_history, { desc = 'Command history' })
vim.keymap.set('n', '<leader>/', builtin.search_history, { desc = 'Search history' })
vim.keymap.set('n', '<leader>fk', builtin.keymaps, { desc = 'Find keymaps' })
vim.keymap.set('n', '<leader>fc', builtin.colorscheme, { desc = 'Find colorschemes' })
vim.keymap.set('n', '<leader>fj', builtin.jumplist, { desc = 'Jumplist' })
vim.keymap.set('n', '<leader>fm', builtin.marks, { desc = 'Marks' })
vim.keymap.set('n', '<leader>fq', builtin.quickfix, { desc = 'Quickfix list' })
vim.keymap.set('n', '<leader>fl', builtin.loclist, { desc = 'Location list' })
