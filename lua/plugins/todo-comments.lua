return {
  'folke/todo-comments.nvim',
  lazy = true,
  event = 'WinEnter',
  opts = {
    signs = false,
    keywords = {
      NOTE = { icon = ' ', color = 'warning', alt = { 'INFO' } },
    },
  },
}
