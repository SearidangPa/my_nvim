return {
  'ibhagwan/fzf-lua',
  lazy = true,
  config = function()
    vim.keymap.set('n', '<leader>sb', function() require('fzf-lua').git_branches {} end,
      { noremap = true, silent = true, desc = '[S]witch [B]ranches' })
  end,
}
