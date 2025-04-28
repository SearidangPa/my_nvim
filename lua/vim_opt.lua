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

-- === luarocks ===

vim.schedule(function() vim.opt.clipboard = 'unnamedplus' end)
