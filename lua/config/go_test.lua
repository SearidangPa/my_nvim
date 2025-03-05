local M = {}
require 'config.util_find_func'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local all_tests_term = {}

local floating_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
}

function Create_floating_window(buf_input)
  buf_input = buf_input or -1
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.columns - width))
  local col = math.floor((vim.o.lines - height))

  local buf = nil
  if buf_input == -1 then
    buf = vim.api.nvim_create_buf(false, true)
  else
    buf = buf_input
  end

  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
  })

  return buf, win
end

local toggle_test_floating_terminal = function()
  if vim.api.nvim_win_is_valid(floating_term_state.win) then
    vim.api.nvim_win_hide(floating_term_state.win)
    return
  end

  floating_term_state.buf, floating_term_state.win = Create_floating_window(floating_term_state.buf)
  if vim.bo[floating_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    floating_term_state.chan = vim.bo.channel
  end
  return floating_term_state.win
end

local get_all_tests_in_buf = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  local concatTestName = ''
  for testName, _ in pairs(testsInCurrBuf) do
    concatTestName = concatTestName .. testName .. '|'
  end
  concatTestName = concatTestName:sub(1, -2) -- remove the last |
  return concatTestName
end

local test_all_in_buf = function()
  local concatTestName = get_all_tests_in_buf()
  local command_str = string.format("go test ./... -v -run '%s'", concatTestName) -- don't forget the single quotes
  toggle_test_floating_terminal()
  vim.api.nvim_chan_send(floating_term_state.chan, command_str .. '\n')
end

local function drive_test_all_staging()
  vim.env.UKS = 'others'
  vim.env.MODE = 'staging'
  local concatTestName = get_all_tests_in_buf()
  local command_str = string.format("go test integration_tests/*.go -v -run '%s'", concatTestName)
  toggle_test_floating_terminal()
  vim.api.nvim_chan_send(floating_term_state.chan, command_str .. '\n')
end

local function drive_test_all_dev()
  vim.env.UKS = 'others'
  vim.env.MODE = 'dev'
  local concatTestName = get_all_tests_in_buf()
  local command_str = string.format("go test integration_tests/*.go -v -run '%s'", concatTestName)
  toggle_test_floating_terminal()
  vim.api.nvim_chan_send(floating_term_state.chan, command_str .. '\n')
end

local go_test = function()
  local test_name = Get_enclosing_test()
  make_notify(string.format('test: %s', test_name))
  local command_str = string.format('go test ./... -v -run %s', test_name)
  toggle_test_floating_terminal()
  vim.api.nvim_chan_send(floating_term_state.chan, command_str .. '\n')
end

vim.api.nvim_create_user_command('GoTest', go_test, {})
vim.api.nvim_create_user_command('GoTestBuf', test_all_in_buf, {})

-- === Drive Test ===

local function drive_test_dev()
  vim.env.UKS = 'others'
  vim.env.MODE = 'dev'
  local test_name = Get_enclosing_test()
  local command_str = string.format('go test integration_tests/*.go -v -run %s', test_name)
  toggle_test_floating_terminal()
  vim.api.nvim_chan_send(floating_term_state.chan, command_str .. '\n')
end

local function drive_test_staging()
  vim.env.UKS = 'others'
  vim.env.MODE = 'staging'
  local test_name = Get_enclosing_test()
  local command_str = string.format('go test integration_tests/*.go -v -run %s', test_name)
  toggle_test_floating_terminal()
  vim.api.nvim_chan_send(floating_term_state.chan, command_str .. '\n')
end

vim.api.nvim_create_user_command('DriveTestDev', drive_test_dev, {})
vim.api.nvim_create_user_command('DriveTestStaging', drive_test_staging, {})
vim.api.nvim_create_user_command('DriveTestAllStaging', drive_test_all_staging, {})
vim.api.nvim_create_user_command('DriveTestAllDev', drive_test_all_dev, {})

vim.keymap.set('n', '<leader>gt', toggle_test_floating_terminal, { desc = 'Toggle go test terminal' })

return M
