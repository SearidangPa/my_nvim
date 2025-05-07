return {
  'folke/todo-comments.nvim',
  lazy = true,
  event = 'BufReadPost',
  opts = {
    signs = false,
    keywords = {
      NOTE = { icon = ' ', color = 'warning', alt = { 'INFO' } },
    },
  },
}
