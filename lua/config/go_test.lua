local M = {}
require 'config.util_find_func'
local ts_utils = require 'nvim-treesitter.ts_utils'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local get_node_text = vim.treesitter.get_node_text

local test_all_in_buf = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  local concatTestName = ''
  for testName, _ in pairs(testsInCurrBuf) do
    concatTestName = concatTestName .. testName .. '|'
  end
  concatTestName = concatTestName:sub(1, -2) -- remove the last |
  local command_str = string.format('go test ./... -json -v -run %s', concatTestName)
end

local go_test = function()
  local test_name = Get_enclosing_test()
  make_notify(string.format('test: %s', test_name))
  local command_str = string.format('go test ./... -json -v -run %s', test_name)
end

vim.api.nvim_create_user_command('GoTest', go_test, {})
vim.api.nvim_create_user_command('GoTestBuf', test_all_in_buf, {})

-- === Drive Test ===

local function drive_test_command()
  local test_name = Get_enclosing_test()
  make_notify(string.format('test: %s', test_name))
  local command_str = string.format('go test integration_tests/*.go -json -v -run %s', test_name)
  return command_str
end

local function drive_test_dev()
  vim.env.UKS = 'others'
  vim.env.MODE = 'dev'
end

local function drive_test_staging()
  vim.env.UKS = 'others'
  vim.env.MODE = 'staging'
end

vim.api.nvim_create_user_command('DriveTestDev', drive_test_dev, {})
vim.api.nvim_create_user_command('DriveTestStaging', drive_test_staging, {})

return M
