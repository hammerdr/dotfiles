vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  use 'tpope/vim-fugitive'
  use 'leafgarland/typescript-vim'
  use 'jose-elias-alvarez/nvim-lsp-ts-utils'
  use 'vim-airline/vim-airline'
  use 'vim-airline/vim-airline-themes'
  use 'pangloss/vim-javascript'
  use 'mxw/vim-jsx'
  use 'tpope/vim-endwise'
  use 'ap/vim-css-color'
  use 'mileszs/ack.vim'
  use 'andrewradev/splitjoin.vim'
  use 'elixir-editors/vim-elixir'
  use 'rust-lang/rust.vim'
  use 'simrat39/rust-tools.nvim'

  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }

  use 'neovim/nvim-lspconfig'
  use 'navarasu/onedark.nvim'

  use {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {}
    end
  }

  use 'nvim-lua/plenary.nvim'

  use 'mfussenegger/nvim-lint'

  use {
    'nvim-telescope/telescope.nvim',
    requires = { {'nvim-lua/plenary.nvim'} }
  }
  use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
end)
