return {
  'SearidangPa/blackboard.nvim',
  event = 'VeryLazy',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function() local bb = require 'blackboard' end,
}
