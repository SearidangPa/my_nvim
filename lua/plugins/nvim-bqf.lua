return {
  'kevinhwang91/nvim-bqf',
  lazy = true,
  version = '*',
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
