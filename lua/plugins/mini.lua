return {
  'echasnovski/mini.nvim',
  lazy = true,
  event = 'BufReadPost',
  version = '*',
  config = function()
    require('mini.ai').setup()
    require('mini.icons').setup()
    require('mini.diff').setup()
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
