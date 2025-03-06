local map = vim.keymap.set
local linter_ns = vim.api.nvim_create_namespace 'linter'

local output = {}
local errors = {}

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

vim.api.nvim_create_user_command('MakeAll', function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j all' }
  else
    cmd = { 'make', '-j', 'all' }
  end
  _, output, errors = Start_job { cmd = cmd }
end, {})

vim.api.nvim_create_user_command('GoModTidy', function()
  local cmd = { 'go', 'mod', 'tidy' }
  _, output, errors = Start_job { cmd = cmd }
end, {})

vim.api.nvim_create_user_command('MakeLint', function()
  local cmd
  if vim.fn.has 'win32' == 1 then
    cmd = { 'C:\\Program Files\\Git\\bin\\bash.exe', '-c', 'make -j lint' }
  else
    cmd = { 'make', '-j', 'lint' }
  end
  _, output, errors = Start_job { cmd = cmd, ns = linter_ns }
end, {})

vim.api.nvim_create_user_command('ClearQuickFix', function()
  vim.fn.setqflist({}, 'r')
  vim.diagnostic.reset(linter_ns)
end, {})

local toggle_float = function(content)
  if vim.api.nvim_win_is_valid(state.floating.win) then
    vim.api.nvim_win_hide(state.floating.win)
    return
  end
  state.floating.buf, state.floating.win = Create_test_floating_window(state.floating.buf)
  vim.api.nvim_buf_set_lines(state.floating.buf, 0, -1, false, content)
end

vim.api.nvim_create_user_command('ToggleOutput', function()
  toggle_float(output)
end, {})

vim.api.nvim_create_user_command('ToggleErrors', function()
  toggle_float(errors)
end, {})

map('n', '<leader>ma', ':MakeAll<CR>', { desc = '[M}ake [A]ll in the background' })
map('n', '<leader>ml', ':MakeLint<CR>', { desc = '[M]ake [L]int' })

return {}
