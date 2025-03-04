return {
  'SearidangPa/gotest.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
  },
  config = function()
    local gotest = require 'gotest'
    gotest.setup {}
  end,
}
