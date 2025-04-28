return {
  'SearidangPa/terminal-multiplexer.nvim',
  lazy = true,
  config = function()
    require 'custom.terminals_daemon'
    require 'custom.git_flow'
  end,
}
