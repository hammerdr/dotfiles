require('lint').linters_by_ft = {
  javascript = {'eslint'},
  typescript = {'eslint'},
  javascriptreact = {'eslint'},
  typescriptreact = {'eslint'},
  jsx = {'eslint'},
  tsx = {'eslint'}
}

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
  group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
  callback = function()
    require("lint").try_lint()
  end,
})
