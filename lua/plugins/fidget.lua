return {
  'j-hui/fidget.nvim', -- fidget.nvim dependency remains
  event = 'LspAttach',
  config = function() require('fidget').setup {} end,
}
