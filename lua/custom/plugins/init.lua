-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- edit: insert mode keymaps
vim.api.nvim_set_keymap('i', '<C-p>', '()<Esc>a', { noremap = true, silent = true, desc = 'Insert parentheses' })

vim.api.nvim_set_keymap('v', 'p', '"_dP', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'dD', '"_dd', { noremap = true, silent = true })

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
vim.keymap.set('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })
vim.keymap.set('n', '<leader>ql', ':clast<CR>', { desc = 'Last Quickfix item' })
vim.keymap.set('n', '<leader>qf', ':cfirst<CR>', { desc = 'First Quickfix item' })

vim.keymap.set('n', '<leader>n', ':cnext<CR>', { desc = 'Next Quickfix item' })
vim.keymap.set('n', '<leader>p', ':cprevious<CR>', { desc = 'Previous Quickfix item' })

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
