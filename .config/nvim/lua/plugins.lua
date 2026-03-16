return require('packer').startup(function()
  use 'wbthomason/packer.nvim'

  use 'tpope/vim-fugitive'
  use 'vim-airline/vim-airline'
  use 'vim-airline/vim-airline-themes'
  use 'tpope/vim-endwise'
  use 'andrewradev/splitjoin.vim'

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
    requires = "nvim-tree/nvim-web-devicons",
    config = function()
      require("trouble").setup {
        auto_close = false,     -- keep panel open even when no diagnostics
        auto_open = false,      -- we handle opening via autocmd below
        auto_refresh = true,    -- refresh diagnostics automatically
        auto_preview = true,    -- show preview when navigating items
        focus = false,          -- don't steal focus from the editor
        follow = true,          -- follow the current item
        open_no_results = true, -- keep window open even with no results
        warn_no_results = false,
        win = {
          type = "split",
          position = "bottom",
          size = { height = 10 },
        },
        modes = {
          diagnostics = {
            auto_open = true,   -- auto-open when diagnostics exist
            auto_close = false, -- stay open even when cleared
          },
        },
      }
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
  use { 'gbrlsnchs/telescope-lsp-handlers.nvim' }
  use { 'dhruvasagar/vim-table-mode' }
  use { 'pmizio/typescript-tools.nvim' }

  use {
    'NickvanDyke/opencode.nvim',
    requires = 'nvim-lua/plenary.nvim',
    config = function()
      require('opencode_config')
    end
  }

end)
