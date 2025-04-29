return {
  'SearidangPa/terminal-multiplexer.nvim',
  lazy = true,
  event = 'VeryLazy',
  config = function()
    require 'custom.terminals_daemon'
    require 'custom.git_flow'
    if vim.fn.has 'win32' ~= 1 then
      require 'custom.push_with_qwen'
    end
    require 'config.scratch'
  end,
}
