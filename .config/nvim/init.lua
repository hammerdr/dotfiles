require('plugins')
require('settings')

-- Set up Claude completion before cmp
require('claude_completion').setup({
  model = 'sonnet',
  claude_path = '/opt/homebrew/bin/claude',
  max_context_lines = 15,
  min_trigger_length = 2,
})

-- Set up manual Claude completion
require('claude_manual_completion').setup()

require('our_cmp')
require('mason_config')
require('lsp')
-- require('copilot_config')  -- Disabled in favor of Claude
require('our_lint')
require('treesitter')
require('our_telescope')
require('codeowners')

-- File watcher utility
require('file_watcher').setup()

-- Claude integration (using synchronous version that works)
require('claude_sync').setup({
  model = 'sonnet',
  claude_path = '/opt/homebrew/bin/claude',
})
