vim.keymap.set('n', '<leader>th1', ':colorscheme kanagawa-wave<CR>', { noremap = true, silent = true, desc = 'change to kanagawa-wave' })
vim.keymap.set('n', '<leader>th2', ':colorscheme github_light_default<CR>', { noremap = true, silent = true, desc = 'change to github_light_default' })

return {
  {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    init = function()
      vim.cmd.colorscheme 'kanagawa-wave'
      vim.cmd.hi 'Comment gui=none'
    end,
  },
  { 'rose-pine/neovim', name = 'rose-pine' },
  { 'folke/tokyonight.nvim', lazy = false, priority = 1000 },
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
  {
    'projekt0n/github-nvim-theme',
    name = 'github-theme',
    priority = 1000,

    -- init = function()
    --   vim.cmd.colorscheme 'github_light_default'
    --   vim.cmd.hi 'Comment gui=none'
    -- end,
  },
}
