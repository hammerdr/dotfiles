local opencode = require('opencode')

opencode.setup({})

-- Keymaps for opencode.nvim
vim.keymap.set('n', '<leader>oa', function() 
  opencode.ask('@cursor: ') 
end, { desc = 'Ask opencode' })

vim.keymap.set('v', '<leader>oa', function() 
  opencode.ask('@selection: ') 
end, { desc = 'Ask opencode about selection' })

vim.keymap.set('n', '<leader>ot', function() 
  opencode.toggle() 
end, { desc = 'Toggle embedded opencode' })

vim.keymap.set('n', '<leader>on', function() 
  opencode.command('session_new') 
end, { desc = 'New session' })

vim.keymap.set('n', '<leader>oy', function() 
  opencode.command('messages_copy') 
end, { desc = 'Copy last message' })

vim.keymap.set('n', '<S-C-u>', function() 
  opencode.command('messages_half_page_up') 
end, { desc = 'Scroll messages up' })

vim.keymap.set('n', '<S-C-d>', function() 
  opencode.command('messages_half_page_down') 
end, { desc = 'Scroll messages down' })

vim.keymap.set({'n', 'v'}, '<leader>op', function() 
  opencode.select_prompt() 
end, { desc = 'Select prompt' })

vim.keymap.set('n', '<leader>oe', function() 
  opencode.prompt("Explain @cursor and its context") 
end, { desc = "Explain code near cursor" })

-- Event listener for opencode events
vim.api.nvim_create_autocmd("User", {
  pattern = "OpencodeEvent",
  callback = function(args)
    if args.data.type == "session.idle" then
      vim.notify("opencode finished responding", vim.log.levels.INFO)
    end
  end,
})