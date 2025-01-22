return {
  'kevinhwang91/nvim-bqf',
  ft = 'qf',
  dependencies = {
    {
      'junegunn/fzf',
      run = function()
        vim.fn['fzf#install']()
      end,
    },
    {
      'nvim-treesitter/nvim-treesitter',
      run = ':TSUpdate',
    },
  },
  config = function()
    require('bqf').setup {
      preview = {
        win_height = 50,
        win_vheight = 50,
      },
    }
  end,
}
