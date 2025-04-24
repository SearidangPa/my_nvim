return {
  'folke/todo-comments.nvim',
  lazy = true,
  event = 'VimEnter',
  dependencies = { 'nvim-lua/plenary.nvim' },
  opts = {
    signs = false,
    keywords = {
      NOTE = { icon = ' ', color = 'warning', alt = { 'INFO' } },
    },
  },
}
