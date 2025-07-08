return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  use 'tpope/vim-fugitive'
  use 'vim-airline/vim-airline'
  use 'vim-airline/vim-airline-themes'
  use 'tpope/vim-endwise'
  use 'ap/vim-css-color'
  use 'mileszs/ack.vim'
  use 'andrewradev/splitjoin.vim'
  use 'simrat39/rust-tools.nvim'

  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate'
  }

  use 'neovim/nvim-lspconfig'
  use 'navarasu/onedark.nvim'
  use 'williamboman/mason.nvim'
  use 'williamboman/mason-lspconfig.nvim'

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

  use {
    'hrsh7th/nvim-cmp',
    requires = {
      {'hrsh7th/cmp-buffer'},
      {'hrsh7th/cmp-nvim-lsp'},
    },
  }

  use { 'discord/vim-codeowners' }
  use { "zbirenbaum/copilot.lua" }
  use { "zbirenbaum/copilot-cmp", after = { "copilot.lua" } }
  use { "L3MON4D3/LuaSnip" }
  use { 'gbrlsnchs/telescope-lsp-handlers.nvim' }
  use { 'dhruvasagar/vim-table-mode' }
  use { 'pmizio/typescript-tools.nvim' }

end)
