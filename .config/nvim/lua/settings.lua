local o = vim.o
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
-- o.listchars = 'tab:»,extends:›,precedes:‹,nbsp:·,trail:·'

require('onedark').setup {
    style = 'warm'
}
require('onedark').load()

-- Remove whitespace on save
cmd [[autocmd BufWritePre * :%s/\s\+$//e]]

-- Don't auto commenting new lines
cmd [[autocmd BufEnter * set fo-=c fo-=r fo-=o]]

-- 2 spaces for selected filetypes
cmd [[
  autocmd FileType xml,html,xhtml,css,scss,typescript,javascript,lua,yaml setlocal shiftwidth=2 tabstop=2
]]
