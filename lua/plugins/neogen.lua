return {
  'danymat/neogen',
  config = function()
    local neogen = require 'neogen'
    neogen.setup {
      snippet_engine = 'luasnip',
    }
  end,
}
