return {
  'j-hui/fidget.nvim', -- fidget.nvim dependency remains
  lazy = true,
  event = 'LspAttach',
  version = '*',
  config = function() require('fidget').setup {} end,
}
