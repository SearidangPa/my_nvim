-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
vim.api.nvim_set_keymap('i', '<C-p>', '()<Esc>a', { noremap = true, silent = true })
vim.api.nvim_set_keymap('i', '<C-q>', '<Esc>la', { noremap = true, silent = true })
vim.api.nvim_set_keymap('v', 'p', '"_dP', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'dD', '"_dd', { noremap = true, silent = true })

vim.cmd [[imap <silent><script> <expr> <C-y> copilot#Accept((("\<CR>")))]]

local function SuggestOneWord()
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']()
  return vim.split(bar, '[ .]\zs')[0]
end

local map = vim.keymap.set
map('i', '<alt-right>', SuggestOneWord, { expr = true, remap = false })

-- diagnostic
vim.keymap.set('n', ']g', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[g', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })

local function toggle_quickfix()
  if vim.fn.getwininfo(vim.fn.win_getid())[1].quickfix == 1 then
    vim.cmd 'cclose'
  else
    vim.cmd 'copen'
  end
end

-- Populate the Quickfix list with diagnostics
vim.keymap.set('n', '<leader>qd', function()
  vim.diagnostic.setqflist()
  vim.cmd 'copen'
end, { desc = 'diagnostic to quickfix' })

vim.keymap.set('n', '<leader>qt', toggle_quickfix, { desc = 'toggle diagnostic windows' })
vim.keymap.set('n', '<leader>qo', ':copen<CR>', { desc = 'Open Quickfix window' })
vim.keymap.set('n', '<leader>n', ':cnext<CR>', { desc = 'Next Quickfix item' })
vim.keymap.set('n', '<leader>p', ':cprevious<CR>', { desc = 'Previous Quickfix item' })
vim.keymap.set('n', '<leader>cl', ':clast<CR>', { desc = 'Last Quickfix item' })
vim.keymap.set('n', '<leader>cf', ':cfirst<CR>', { desc = 'First Quickfix item' })


return {
  {
    {
      'ray-x/lsp_signature.nvim',
      event = 'InsertEnter',
      opts = {
        bind = true,
        handler_opts = {
          border = 'rounded',
        },
      },
      config = function(_, opts)
        require('lsp_signature').setup(opts)
      end,
    },
  },

  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },

    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup {}

      -- basic telescope configuration
      local conf = require('telescope.config').values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require('telescope.pickers')
          .new({}, {
            prompt_title = 'Harpoon',
            finder = require('telescope.finders').new_table {
              results = file_paths,
            },
            previewer = conf.file_previewer {},
            sorter = conf.generic_sorter {},
          })
          :find()
      end

      vim.keymap.set('n', '<leader>a', function()
        harpoon:list():add()
      end, { desc = 'add to harpoon' })

      vim.keymap.set('n', '<A-1>', function()
        harpoon:list():select(1)
      end, { desc = 'harpoon 1' })

      vim.keymap.set('n', '<A-2>', function()
        harpoon:list():select(2)
      end, { desc = 'harpoon 2' })

      vim.keymap.set('n', '<A-3>', function()
        harpoon:list():select(3)
      end, { desc = 'harpoon 3' })

      vim.keymap.set('n', '<A-4>', function()
        harpoon:list():select(4)
      end, { desc = 'harpoon 4' })

      vim.keymap.set('n', '<leader>fh', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = 'Harpoon (Default)' })

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set('n', '<A-p>', function()
        harpoon:list():prev()
      end, { desc = 'prev in harpoon' })
      vim.keymap.set('n', '<A-n>', function()
        harpoon:list():next()
      end, { desc = 'next in harpoon' })

      vim.keymap.set('n', '<C-e>', function()
        toggle_telescope(harpoon:list())
      end, { desc = 'Open harpoon window' })
    end,
  },

  {
    'zbirenbaum/copilot.lua',
    cmd = 'Copilot',
    build = ':Copilot auth',
    opts = {
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
      },
    },
  },
}
