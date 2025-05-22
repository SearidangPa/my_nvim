local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

map(
  { 'v', 'n' },
  '<localleader>av',
  function() require('codecompanion').prompt 'docfn' end,
  { noremap = true, silent = true, desc = '[A]dd doc to a visual selected block' }
)
