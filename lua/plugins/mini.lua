return {
  'echasnovski/mini.nvim',
  lazy = true,
  event = 'BufReadPost',
  config = function()
    require('mini.ai').setup()
    require('mini.icons').setup()
    require('mini.diff').setup()
    require('mini.notify').setup {
      lsp_progress = {
        enable = false,
      },
      window = {
        config = {
          anchor = 'NE',
          col = vim.o.columns,
          row = math.floor(vim.o.lines / 2),
        },
      },
    }
  end,
}
