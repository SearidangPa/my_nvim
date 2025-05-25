vim.g.mapleader = ' '
vim.g.maplocalleader = ','
vim.g.copilot_no_tab_map = true -- copilot plugin config

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
vim.opt.relativenumber = true
vim.opt.signcolumn = 'yes'
vim.opt.numberwidth = 1
vim.opt.cmdheight = 1
vim.opt.cursorline = true
vim.opt.breakindent = true

--- === Live Preview ===
vim.opt.inccommand = 'nosplit' -- Preview substitutions live, as you type
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- === some more functionality ===
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.mouse = 'a'
vim.g.have_nerd_font = true
vim.opt.shell = 'fish'

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

vim.api.nvim_create_autocmd('UIEnter', {
  callback = function()
    local function load_modules(dir)
      local path = vim.fs.joinpath(vim.fn.stdpath 'config', 'lua', dir)
      local files = vim.fn.readdir(path)

      for _, file in ipairs(files) do
        if file:match '%.lua$' and not (file:match '^util_') then
          local module_name = file:gsub('%.lua$', '')
          require(dir .. '.' .. module_name)
        end
      end
    end
    load_modules 'keymaps'
    load_modules 'custom'
    vim.treesitter.language.register('bash', 'zsh')
  end,
})
