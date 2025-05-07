return {
  'kevinhwang91/nvim-bqf',
  lazy = true,
  event = 'BufReadPost',
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
