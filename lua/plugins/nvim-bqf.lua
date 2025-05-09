return {
  'kevinhwang91/nvim-bqf',
  lazy = true,
  event = { 'LspAttach' },
  ft = 'qf',
  opts = {
    preview = {
      win_vheight = 999,
      win_height = 999,
    },
  },
}
