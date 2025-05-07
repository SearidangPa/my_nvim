return {
  'nvim-tree/nvim-web-devicons',
  lazy = true,
  version = '*',
  event = 'BufReadPost',
  enabled = vim.g.have_nerd_font,
}
