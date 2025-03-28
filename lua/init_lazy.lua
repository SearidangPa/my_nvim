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

local hererocks_enabled = true
if vim.fn.has 'win32' == 1 then
  hererocks_enabled = false
end

require('lazy').setup {
  spec = {
    {
      import = 'plugins',
    },
    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
    'tpope/vim-rhubarb', -- Fugitive-companion to interact with github
    'mbbill/undotree', -- Visualize the undo tree
    'MTDL9/vim-log-highlighting',
    'MunifTanjim/nui.nvim',
    {
      'grapp-dev/nui-components.nvim',
      dependencies = {
        'MunifTanjim/nui.nvim',
      },
    },
  },
  rocks = {
    hererocks = hererocks_enabled,
  },
  checker = { enabled = false, frequency = 60 * 60 * 24 * 7 }, -- automatically check for plugin updates every week
  change_detection = { enabled = false },
}
