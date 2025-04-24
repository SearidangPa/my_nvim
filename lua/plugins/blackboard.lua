return {
  'SearidangPa/blackboard.nvim',
  event = 'VeryLazy',
  lazy = true,
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function() local bb = require 'blackboard' end,
}
