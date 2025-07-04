require('plugins')
require('settings')

-- Set up Claude completion before cmp
require('claude_completion').setup({
  model = 'sonnet',
  claude_path = '/opt/homebrew/bin/claude',
  max_context_lines = 15,
  min_trigger_length = 2,
})

require('our_cmp')
require('lsp')
-- require('copilot_config')  -- Disabled in favor of Claude
require('our_lint')
require('treesitter')
require('our_telescope')
require('codeowners')

-- Claude integration (using synchronous version that works)
require('claude_sync').setup({
  model = 'sonnet',
  claude_path = '/opt/homebrew/bin/claude',
})
