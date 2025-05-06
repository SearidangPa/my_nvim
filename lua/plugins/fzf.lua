return {
  'ibhagwan/fzf-lua',
  lazy = true,
  version = '*',
  event = 'WinEnter',
  config = function()
    vim.keymap.set('n', '<localleader>sb', function() require('fzf-lua').git_branches {} end, { noremap = true, silent = true, desc = '[S]witch [B]ranches' })
  end,
}
