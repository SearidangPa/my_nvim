---@class SnackHarpoon
---@field pick_harpoon fun()
local M = {}

M.pick_harpoon = function()
  local harpoon = require 'harpoon'
  local harpoon_files = harpoon:list()

  local file_paths = {}
  for _, item in ipairs(harpoon_files.items) do
    table.insert(file_paths, item.value)
  end

  require('snacks.picker').select(file_paths, {
    prompt = 'Harpoon',
    format_item = function(item) return vim.fn.fnamemodify(item, ':t') end,
    kind = 'Harpoon',
  }, function(choice, _)
    if choice then
      vim.cmd('edit ' .. choice)
    end
  end)
end

return M
