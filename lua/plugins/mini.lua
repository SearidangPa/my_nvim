return {
  'echasnovski/mini.nvim',
  event = 'VeryLazy',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.icons').setup {}
    local win_config = function()
      return {
        anchor = 'NE',
        col = vim.o.columns,
        row = math.floor(vim.o.lines / 2),
      }
    end
    require('mini.notify').setup {
      lsp_progress = {
        enable = false,
      },
      window = { config = win_config },
    }
  end,
}
