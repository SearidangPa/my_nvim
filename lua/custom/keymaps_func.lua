local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

local function yank_function()
  local bufnr = vim.api.nvim_get_current_buf()
  local util_find_func = require 'custom.util_find_func'
  local func_node = util_find_func.nearest_func_node()
  local func_text = vim.treesitter.get_node_text(func_node, bufnr)
  vim.fn.setreg('*', func_text)
  for child in func_node:iter_children() do
    if child:type() == 'identifier' or child:type() == 'name' then
      local func_name = vim.treesitter.get_node_text(child, bufnr)
      print('Yanked function: ' .. func_name)
      break
    end
  end
end

map('n', '<leader>yf', yank_function, map_opt '[Y]ank [F]unction')
