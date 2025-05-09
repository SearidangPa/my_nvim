return {
  'kevinhwang91/nvim-bqf',
  lazy = true,
  event = { 'LspAttach', 'BufWritePost' },
  ft = 'qf',
  opts = {
    preview = {
      win_vheight = 999,
      win_height = 999,
    },
  },
}
