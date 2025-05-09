return {
  'stevearc/oil.nvim',
  lazy = true,
  event = { 'LspAttach', 'WinEnter' },
  opts = {
    view_options = {
      show_hidden = true,
    },
  },
}
