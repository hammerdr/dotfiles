local o = vim.o
local g = vim.g
local cmd = vim.cmd

o.mouse = 'a'
o.clipboard = 'unnamedplus'
o.swapfile = false
o.completeopt = 'menuone,noselect'

o.number = true
o.showmatch = true
o.splitright = true
o.splitbelow = true
o.ignorecase = true
o.smartcase = true
o.termguicolors = true
o.cmdheight = 2

o.expandtab = true
o.shiftwidth = 4
o.softtabstop = 4
o.tabstop = 4
o.autoindent = true

o.hidden = true

o.list = true
o.listchars = 'tab:» ,extends:›,precedes:‹,nbsp:·,trail:·'

g.mapleader = ","

require('onedark').setup {
    style = 'warm'
}
require('onedark').load()

-- Remove whitespace on save
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = '*',
  callback = function()
    local save_cursor = vim.fn.getpos('.')
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos('.', save_cursor)
  end,
})

-- Don't auto commenting new lines
vim.api.nvim_create_autocmd('BufEnter', {
  pattern = '*',
  callback = function()
    vim.opt.formatoptions:remove({ 'c', 'r', 'o' })
  end,
})

-- 2 spaces for selected filetypes
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'xml', 'html', 'xhtml', 'css', 'scss', 'typescript', 'javascript', 'typescriptreact', 'javascriptreact', 'tsx', 'jsx', 'lua', 'yaml' },
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
})

vim.api.nvim_create_user_command('A', function()
  local ext = vim.fn.expand('%:e')
  if ext == 'css' then
    local newfile = vim.fn.expand('%:p:r:r') .. '.tsx'
    vim.cmd('e ' .. newfile)
  else
    local newfile = vim.fn.expand('%:p:r') .. '.module.css'
    vim.cmd('e ' .. newfile)
  end
end, {})
