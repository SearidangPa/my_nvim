return {
  'echasnovski/mini.nvim',
  lazy = true,
  event = 'BufReadPost',
  config = function()
    require('mini.ai').setup()
    require('mini.icons').setup()
    require('mini.diff').setup()
  end,
}
