return {
  'kevinhwang91/nvim-bqf',
  lazy = true,
  ft = 'qf',
  dependencies = {
    {
      'junegunn/fzf',
      run = function() vim.fn['fzf#install']() end,
    },
    {
      'nvim-treesitter/nvim-treesitter',
      run = ':TSUpdate',
    },
  },
  config = function()
    require('bqf').setup {
      preview = {
        win_vheight = 999,
        win_height = 999,
      },
    }
  end,
}
