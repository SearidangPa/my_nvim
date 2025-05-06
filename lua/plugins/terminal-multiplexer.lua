return {
  'SearidangPa/terminal-multiplexer.nvim',
  lazy = true,
  event = 'BufReadPost',
  config = function()
    require 'custom.terminals_daemon'
    require 'custom.git_flow'
    if vim.fn.has 'win32' ~= 1 then
      require 'custom.push_with_qwen'
    end
    require 'config.scratch'
    require 'custom.async_job'

    vim.api.nvim_create_autocmd('TermOpen', {
      pattern = '*',
      callback = function() vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':q<CR>', { noremap = true, silent = true }) end,
    })
  end,
}
