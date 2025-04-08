return {
  'SearidangPa/test-t.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
  },
  config = function() require('test-t').setup() end,
}
