-- Diagnostic keymaps
local opts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, opts)
vim.keymap.set('n', '[d', function() vim.diagnostic.jump({ count = -1 }) end, opts)
vim.keymap.set('n', ']d', function() vim.diagnostic.jump({ count = 1 }) end, opts)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, opts)

-- Buffer-local keymaps when LSP attaches
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user_lsp_attach', { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local bufopts = { noremap=true, silent=true, buffer=bufnr }

    -- Open Trouble diagnostics panel when LSP attaches (if not already open)
    vim.defer_fn(function()
      if not require('trouble').is_open() then
        require('trouble').open({ mode = 'diagnostics', focus = false })
      end
    end, 200)

    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, bufopts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, bufopts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, bufopts)
    vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, bufopts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, bufopts)
  end,
})

-- Configure LSP servers using the new vim.lsp.config API
vim.lsp.config('rust_analyzer', {
  capabilities = _G.completion_capabilities,
  settings = {},
})

vim.lsp.config('elixirls', {
  cmd = { vim.fn.expand("~/.elixirls/language_server.sh") },
  capabilities = _G.completion_capabilities,
})

vim.lsp.config('pylsp', {
  capabilities = _G.completion_capabilities,
})

-- Enable the configured servers
vim.lsp.enable({ 'rust_analyzer', 'elixirls', 'pylsp' })

-- typescript-tools has its own setup, separate from lspconfig
require('typescript-tools').setup {
  capabilities = _G.completion_capabilities,
}
