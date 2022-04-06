vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  use 'tpope/vim-fugitive'
  use 'ctrlpvim/ctrlp.vim'
  use 'leafgarland/typescript-vim'
  use 'vim-airline/vim-airline'
  use 'vim-airline/vim-airline-themes'
  use 'pangloss/vim-javascript'
  use 'mxw/vim-jsx'
  use 'tpope/vim-endwise'
  use 'ap/vim-css-color'
  use 'mileszs/ack.vim'
  use 'andrewradev/splitjoin.vim'

  use {
    'w0rp/ale',
    cmd = 'ALEEnable',
    config = 'vim.cmd[[ALEEnable]]'
  }
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }

  use 'neovim/nvim-lspconfig'
  use 'navarasu/onedark.nvim'
end)
