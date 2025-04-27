return {
  'SearidangPa/blackboard.nvim',
  lazy = true,
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function() local bb = require 'blackboard' end,
}
