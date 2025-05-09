return {
  'folke/todo-comments.nvim',
  lazy = true,
  event = { 'LspAttach' },
  opts = {
    signs = false,
    keywords = {
      NOTE = { icon = ' ', color = 'warning', alt = { 'INFO' } },
    },
  },
}
