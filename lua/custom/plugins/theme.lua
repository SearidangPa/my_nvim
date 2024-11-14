return {
  {
    'rebelot/kanagawa.nvim',
    priority = 1000,
    init = function()
      -- Like many other themes, this one has different styles, and you could load
      -- any other, such as 'tokyonight-storm', 'tokyonight-moon', or 'tokyonight-day'.
      vim.cmd.colorscheme 'kanagawa'

      -- You can configure highlights by doing something like:
      vim.cmd.hi 'Comment gui=none'
    end,
  },
  { 'rose-pine/neovim', name = 'rose-pine' },
  {
    'folke/tokyonight.nvim',
    lazy = false,
    priority = 1000,
    opts = {},
  },
  { 'catppuccin/nvim', name = 'catppuccin', priority = 1000 },
}
