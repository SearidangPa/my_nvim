vim.g.mapleader = ' '
vim.g.maplocalleader = ','
vim.g.copilot_no_tab_map = true -- copilot plugin config
vim.g.undotree_WindowLayout = 2 -- undo tree plugin config
require 'init_opt'
require 'init_lazy' -- must be before leader mappings
require 'init_config'

vim.treesitter.language.register('bash', 'zsh') -- ducktape solution because there is no treesitter support for zsh

local yank_group = vim.api.nvim_create_augroup('HighlightYank', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = yank_group,
  callback = function() vim.highlight.on_yank() end,
})

if vim.o.background == 'light' then
  vim.cmd.colorscheme 'catppuccin-latte'
else
  vim.cmd.colorscheme 'rose-pine-moon'
end
