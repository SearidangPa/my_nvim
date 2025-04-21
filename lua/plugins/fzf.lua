return {
  'ibhagwan/fzf-lua',
  event = 'VeryLazy',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    vim.keymap.set('n', '<leader>sb', function() require('fzf-lua').git_branches {} end, { noremap = true, silent = true })
  end,
}
