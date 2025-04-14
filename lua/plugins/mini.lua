return { -- Collection of various small independent plugins/modules
  'echasnovski/mini.nvim',
  config = function()
    require('mini.ai').setup { n_lines = 500 }
    require('mini.icons').setup {}

    local win_config = function()
      local has_statusline = vim.o.laststatus > 0
      local pad = vim.o.cmdheight + (has_statusline and 1 or 0)
      return { anchor = 'SE', col = vim.o.columns, row = vim.o.lines - pad }
    end
    require('mini.notify').setup {
      lsp_progress = {
        enable = false,
      },
      window = { config = win_config },
    }
  end,
}
