return {
  'nvim-tree/nvim-web-devicons',
  lazy = true,
  version = '*',
  event = { 'LspAttach', 'BufWritePost' },
  enabled = vim.g.have_nerd_font,
}
