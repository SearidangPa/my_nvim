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
vim.opt.numberwidth = 1
vim.opt.tabstop = 6

--- === Live Preview ===
vim.opt.inccommand = 'nosplit' -- Preview substitutions live, as you type!
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- === Duh ===
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.mouse = 'a'
vim.g.have_nerd_font = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.cursorline = true
vim.opt.breakindent = true

vim.api.nvim_create_autocmd('BufFilePre', {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local full_path = vim.api.nvim_buf_get_name(bufnr)
    local cwd = vim.fn.getcwd()

    -- Normalize path separators on Windows
    if vim.fn.has 'win32' == 1 then
      full_path = full_path:gsub('\\', '/')
      cwd = cwd:gsub('\\', '/')
    end

    -- Ensure cwd ends with a slash
    if cwd:sub(-1) ~= '/' then
      cwd = cwd .. '/'
    end

    -- Check if the path is within the current working directory
    if full_path:sub(1, #cwd) == cwd then
      local relative_path = full_path:sub(#cwd + 1)
      vim.api.nvim_buf_set_name(bufnr, relative_path)
    end
  end,
  desc = 'Convert absolute paths to relative paths on BufEnter',
})

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
