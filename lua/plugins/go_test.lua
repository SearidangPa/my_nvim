return {
  'SearidangPa/go_test.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
  },
  config = function()
    local gotest = require 'go_test'
    gotest.setup {}
  end,
}
