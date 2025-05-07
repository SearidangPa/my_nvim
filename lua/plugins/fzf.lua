return {
  'ibhagwan/fzf-lua',
  lazy = true,
  version = '*',
  event = 'BufReadPost',
  config = function()
    vim.keymap.set(
      'n',
      '<localleader>sb',
      function() require('fzf-lua').git_branches {} end,
      { noremap = true, silent = true, desc = '[S]earch remote and local [B]ranches' }
    )
  end,
}
