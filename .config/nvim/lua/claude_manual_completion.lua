local M = {}

-- Use the existing claude_completion module
local claude_completion = require('claude_completion')

-- Track if we're in manual claude mode
local claude_mode_active = false

-- Function to manually trigger Claude completion
function M.trigger_claude_completion()
  local cmp = require('cmp')
  
  -- If cmp menu is already visible and we're in claude mode, confirm selection
  if cmp.visible() and claude_mode_active then
    cmp.confirm({ select = true })
    claude_mode_active = false
    return
  end
  
  -- Otherwise, trigger Claude completion
  claude_mode_active = true
  
  -- Temporarily add Claude source and trigger completion
  cmp.setup.buffer({
    sources = cmp.config.sources({
      { name = 'claude', group_index = 1, priority = 1000 }
    })
  })
  
  -- Trigger completion
  cmp.complete()
  
  -- Reset sources after a short delay
  vim.defer_fn(function()
    if not cmp.visible() then
      claude_mode_active = false
      -- Restore original sources
      cmp.setup.buffer({
        sources = cmp.config.sources({
          { name = 'nvim_lsp', group_index = 1 },
          { name = 'luasnip', group_index = 1 },
        }, {
          { name = 'buffer' },
        })
      })
    end
  end, 100)
end

-- Alternative approach: Direct completion without cmp menu
function M.direct_claude_completion()
  local context = claude_completion.get_completion_context()
  
  if not context then
    vim.notify("Failed to get completion context", vim.log.levels.ERROR)
    return
  end
  
  -- Show loading indicator
  vim.notify("Getting Claude completion...", vim.log.levels.INFO)
  
  -- Get completion asynchronously
  vim.defer_fn(function()
    local completion = claude_completion.get_claude_completion(context)
    
    if completion and completion ~= "NO_COMPLETION" then
      -- Insert the completion at cursor
      local cursor = vim.api.nvim_win_get_cursor(0)
      local row = cursor[1] - 1
      local col = cursor[2]
      
      vim.api.nvim_buf_set_text(0, row, col, row, col, {completion})
      vim.notify("Claude completion inserted", vim.log.levels.INFO)
    else
      vim.notify("No Claude completion available", vim.log.levels.WARN)
    end
  end, 0)
end

-- Setup function
function M.setup()
  -- Create a command for testing
  vim.api.nvim_create_user_command('ClaudeComplete', function()
    M.trigger_claude_completion()
  end, {})
  
  vim.api.nvim_create_user_command('ClaudeCompleteDirect', function()
    M.direct_claude_completion()
  end, {})
end

return M