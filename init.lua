vim.g.mapleader = ','
vim.g.maplocalleader = ' '
vim.g.copilot_no_tab_map = true -- copilot plugin config
vim.g.undotree_WindowLayout = 2 -- undo tree plugin config
--- === case insensitive search, unless capital letter is used ===
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- === Time Periods ===
vim.opt.timeoutlen = 300
vim.opt.updatetime = 50

-- === Files ===
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- === UI ===
vim.opt.list = true
vim.opt.listchars = { tab = '   ', trail = '·', nbsp = '␣' }
vim.opt.scrolloff = 10
vim.opt.showtabline = 1 -- show tabline only when there are multiple tabs

--- === Live Preview ===
vim.opt.inccommand = 'nosplit' -- Preview substitutions live, as you type!
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- === Duh ===
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.mouse = 'a'
vim.g.have_nerd_font = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.breakindent = true
vim.opt.signcolumn = 'yes'

vim.schedule(function() vim.opt.clipboard = 'unnamedplus' end)

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
  spec = {
    {
      import = 'plugins',
    },
  },
  checker = { enabled = false },
  change_detection = {
    enabled = false,
  },
}

require 'config.keymaps'

vim.treesitter.language.register('bash', 'zsh') -- ducktape solution because there is no treesitter support for zsh

local yank_group = vim.api.nvim_create_augroup('HighlightYank', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = yank_group,
  callback = function() vim.highlight.on_yank() end,
})
