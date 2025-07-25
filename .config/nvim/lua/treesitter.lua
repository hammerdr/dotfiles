require('nvim-treesitter.configs').setup {
  ensure_installed = { "elixir", "heex", "eex" },
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  },
}
