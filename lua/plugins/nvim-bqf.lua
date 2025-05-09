return {
  'kevinhwang91/nvim-bqf',
  lazy = true,
  event = { 'LspAttach', 'BufWritePost' },
  ft = 'qf',
  config = function()
    require('bqf').setup {
      preview = {
        win_vheight = 999,
        win_height = 999,
      },
    }
  end,
}
