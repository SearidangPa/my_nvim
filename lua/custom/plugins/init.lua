-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--

-- edit: insert mode keymaps

vim.api.nvim_set_keymap('v', 'p', '"_dP', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', 'dD', '"_dd', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<m-d>', 'vb"_da', { noremap = true, silent = true })

-- lua
vim.api.nvim_create_user_command('Source', 'source %', {})
vim.api.nvim_set_keymap('n', '<leader>x', ':Source<CR>', { noremap = true, silent = true, desc = 'source %' })

vim.api.nvim_set_keymap('n', '<m-r>', ':LspRestart<CR>', { desc = 'Restart LSP' })
vim.api.nvim_set_keymap('n', '<m-q>', ':LspStop', { desc = 'Stop LSP' })

-- Copilot
local function SuggestOneWord()
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']()
  return vim.split(bar, '[ .]\zs')[0]
end

local function SuggestLine()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end

local map = vim.keymap.set
map('i', '<alt-right>', SuggestOneWord, { expr = true, remap = false })
map('i', '<m-l>', SuggestLine, { expr = true, remap = false })

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

vim.keymap.set('n', ',q', function()
  vim.diagnostic.setqflist()
  vim.cmd 'copen'
end, { desc = 'Populate the Quickfix list with diagnostics' })

vim.keymap.set('n', ',,', toggle_quickfix, { desc = 'toggle diagnostic windows' })
-- vim.keymap.set('n', '<leader>qo', ':copen<CR>', { desc = 'Open Quickfix window' })
-- vim.keymap.set('n', '<leader>qc', ':cclose<CR>', { desc = 'Close Quickfix window' })
-- vim.keymap.set('n', '<leader>ql', ':clast<CR>', { desc = 'Last Quickfix item' })
-- vim.keymap.set('n', '<leader>qf', ':cfirst<CR>', { desc = 'First Quickfix item' })

vim.keymap.set('n', '<leader>n', ':cnext<CR>', { desc = 'Next Quickfix item' })
vim.keymap.set('n', '<leader>p', ':cprevious<CR>', { desc = 'Previous Quickfix item' })

vim.api.nvim_create_user_command('Make', function()
  if vim.fn.has 'win32' == 1 then
    vim.cmd [[!"C:\Program Files\Git\bin\bash.exe" -c "rm bin/cloud-drive.exe && make -j all"]]
  else
    vim.cmd [[!make -j all]]
  end
end, {})

vim.keymap.set('n', '<leader>m', ':Make<CR>', { desc = 'Run make' })

vim.api.nvim_create_user_command('GoModTidy', function()
  vim.cmd [[!go mod tidy]]
end, { desc = 'Run go mod tidy' })

vim.keymap.set('n', '<leader>gmt', ':GoModTidy<CR>', { desc = 'Run go mod tidy' })

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
}
