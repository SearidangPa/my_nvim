return {
  'folke/todo-comments.nvim',
  lazy = true,
  event = 'VeryLazy',
  opts = {
    signs = false,
    keywords = {
      NOTE = { icon = ' ', color = 'warning', alt = { 'INFO' } },
    },
  },
}
