return {
  'ibhagwan/fzf-lua',
  lazy = true,
  version = '*',
  event = 'VeryLazy',
  config = function()
    vim.keymap.set('n', '<leader>sb', function() require('fzf-lua').git_branches {} end, { noremap = true, silent = true, desc = '[S]witch [B]ranches' })
  end,
}
