local tr = require 'trouble'
vim.keymap.set('n', ']d', function()
  ---@diagnostic disable-next-line: missing-fields
  tr.next {}
  ---@diagnostic disable-next-line: missing-fields
  tr.jump {}
end, { silent = true, noremap = true, desc = 'Go to next trouble item' })

vim.keymap.set('n', '[d', function()
  tr.prev {}
  tr.jump {}
end, { silent = true, noremap = true, desc = 'Go to previous trouble item' })

local open_with_trouble = require('trouble.sources.telescope').open
local telescope = require 'telescope'
telescope.setup {
  defaults = {
    mappings = {
      i = { ['<c-t>'] = open_with_trouble },
      n = { ['<c-t>'] = open_with_trouble },
    },
  },
}
