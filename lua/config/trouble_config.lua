local tr = require 'trouble'
local map = vim.keymap.set
local function map_opt(desc)
  return { noremap = true, silent = true, desc = desc }
end

map('n', ']d', function()
  ---@diagnostic disable-next-line: missing-fields
  tr.next {}
  ---@diagnostic disable-next-line: missing-fields
  tr.jump {}
end, { silent = true, noremap = true, desc = 'Go to next trouble item' })

map('n', '[d', function()
  tr.prev {}
  tr.jump {}
end, { silent = true, noremap = true, desc = 'Go to previous trouble item' })

map('n', '<leader>tq', function()
  tr.close {}
end, map_opt 'Close trouble')

map('n', '<leader>to', function()
  tr.open {}
end, map_opt 'Open trouble')

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
