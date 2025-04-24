return {
  'j-hui/fidget.nvim', -- fidget.nvim dependency remains
  lazy = true,
  event = 'LspAttach',
  config = function() require('fidget').setup {} end,
}
