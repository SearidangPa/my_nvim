local tr = require 'trouble'
local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

map('n', ']d', function()
  ---@diagnostic disable-next-line: missing-fields
  tr.next {}
  ---@diagnostic disable-next-line: missing-fields
  tr.jump {}
end, { silent = true, noremap = true, desc = 'Go to next trouble item' })

map('n', '[d', function()
  ---@diagnostic disable-next-line: missing-fields
  tr.prev {}
  ---@diagnostic disable-next-line: missing-fields
  tr.jump {}
end, { silent = true, noremap = true, desc = 'Go to previous trouble item' })

map('n', '<localleader>tc', function() tr.close() end, map_opt '[T]rouble [C]lose')

map('n', '<localleader>to', function() tr.open() end, map_opt 'Open trouble')
