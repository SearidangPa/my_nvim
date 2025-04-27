return {
  'folke/todo-comments.nvim',
  lazy = true,
  event = 'BufEnter',
  opts = {
    signs = false,
    keywords = {
      NOTE = { icon = ' ', color = 'warning', alt = { 'INFO' } },
    },
  },
}
