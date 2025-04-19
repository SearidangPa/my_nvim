vim.g.mapleader = ' '
vim.g.maplocalleader = ','
vim.g.copilot_no_tab_map = true -- copilot plugin config
vim.g.undotree_WindowLayout = 2 -- undo tree plugin config
require 'vim_opt'
require 'init_lazy' -- must be before leader mappings
require 'init_config'

local handle = io.popen 'defaults read -g AppleInterfaceStyle 2>/dev/null || echo "Light"'
assert(handle, 'Failed to run command')
local result = handle:read '*a'
handle:close()

if result:match 'Dark' then
  vim.o.background = 'dark'
  vim.cmd.colorscheme 'rose-pine-moon'
else
  vim.o.background = 'light'
  vim.cmd.colorscheme 'github_light_default'
end

vim.treesitter.language.register('bash', 'zsh') -- ducktape solution because there is no treesitter support for zsh

local yank_group = vim.api.nvim_create_augroup('HighlightYank', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = yank_group,
  callback = function() vim.highlight.on_yank() end,
})
