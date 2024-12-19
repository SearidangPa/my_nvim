vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

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

vim.o.tabline = '%!v:lua.TabLine()'
function _G.TabLine()
  local s = ''
  for i = 1, vim.fn.tabpagenr '$' do
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = vim.fn.tabpagebuflist(i)[winnr]
    local bufname = vim.fn.bufname(bufnr)
    local filename = vim.fn.fnamemodify(bufname, ':t') -- Extract only the filename
    if i == vim.fn.tabpagenr() then
      s = s .. '%#TabLineSel#' .. ' ' .. filename .. ' '
    else
      s = s .. '%#TabLine#' .. ' ' .. filename .. ' '
    end
  end
  s = s .. '%#TabLineFill#'
  return s
end

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
      { out,                            'WarningMsg' },
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
    'tpope/vim-sleuth',   -- Detect tabstop and shiftwidth automatically
    'copilot.vim',
  },
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
    local filename = file:match("^.*/([^/\\]+)$")
    require('config.' .. filename:match '(.+).lua')
  end
end)
