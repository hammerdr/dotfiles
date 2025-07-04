local cmp = require('cmp')
local luasnip = require('luasnip')
local claude_manual = require('claude_manual_completion')

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        -- Check for double Tab press for Claude completion
        local last_tab_time = vim.g.last_tab_time or 0
        local current_time = vim.loop.now()
        
        if current_time - last_tab_time < 300 then -- 300ms window for double tap
          claude_manual.trigger_claude_completion()
          vim.g.last_tab_time = 0
        else
          vim.g.last_tab_time = current_time
          fallback()
        end
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp', group_index = 1 },
    { name = 'luasnip', group_index = 1 },
  }, {
    { name = 'buffer' },
  })
})

-- Make completion capabilities available globally for LSP setup
_G.completion_capabilities = require('cmp_nvim_lsp').default_capabilities()
