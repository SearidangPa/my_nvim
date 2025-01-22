vim.g.mapleader = ' '
vim.g.maplocalleader = ','

vim.g.have_nerd_font = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split' -- Preview substitutions live, as you type!
vim.opt.cursorline = true
vim.opt.scrolloff = 10

-- undo tree plugin config
vim.g.undotree_WindowLayout = 2

-- folding
vim.opt.foldmethod = 'expr'
vim.opt.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
vim.opt.foldcolumn = '0'
vim.opt.foldtext = ''
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 1
vim.opt.foldnestmax = 3
vim.opt.foldminlines = 6

vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'
end)

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
    'tpope/vim-fugitive', -- Git commands in Neovim
    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
    { 'github/copilot.vim' },
    'mbbill/undotree', -- Visualize the undo tree
  },
  checker = { enabled = false, frequency = 60 * 60 * 24 * 7 }, -- automatically check for plugin updates every week
  change_detection = { enabled = false },
}

vim.schedule(function()
  local stdpath = vim.fn.stdpath 'config'
  local config_path
  if vim.fn.has 'win32' == 1 then
    config_path = stdpath .. '\\lua\\config'
  else
    config_path = stdpath .. '/lua/config'
  end

  --@diagnostic disable-next-line: param-type-mismatch
  local files = vim.fn.globpath(config_path, '*.lua', true, true)
  for _, file in ipairs(files) do
    local module = vim.fn.fnamemodify(file, ':t:r')
    if not string.match(module, 'util_') then
      require('config.' .. module)
    end
  end
end)
