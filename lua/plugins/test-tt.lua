return {
  'SearidangPa/go-test-tt.nvim',
  dependencies = {
    'echasnovski/mini.nvim',
  },
  config = function() require('go-test-tt').setup() end,
}
