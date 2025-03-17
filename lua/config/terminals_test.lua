local M = {}
require 'config.util_find_func'
local make_notify = require('mini.notify').make_notify {}
local ns = vim.api.nvim_create_namespace 'GoTestError'
local TerminalMultiplexer = require 'config.terminal_multiplexer'
local terminal_multiplexer = TerminalMultiplexer.new()
local map = vim.keymap.set

---@class testInfo
---@field test_name string
---@field test_line number
---@field test_bufnr number
---@field test_command string
---@field status string

---@type testInfo[]
M.test_tracker = {}

M.reset_test = function()
  for test_name, _ in pairs(terminal_multiplexer.all_terminals) do
    terminal_multiplexer:delete_terminal(test_name)
  end

  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
  M.test_tracker = {}
end

-- Function to jump to a specific tracked test by index
local function jump_to_tracked_test_by_index(index)
  if index > #M.test_tracker then
    index = #M.test_tracker
  end
  if index < 1 then
    vim.notify(string.format('Invalid index: %d', index), vim.log.levels.ERROR)
    return
  end

  local target_test = M.test_tracker[index].test_name

  vim.lsp.buf_request(0, 'workspace/symbol', { query = target_test }, function(err, res)
    if err or not res or #res == 0 then
      vim.notify('No definition found for test: ' .. target_test, vim.log.levels.ERROR)
      return
    end

    local result = res[1] -- Take the first result
    local filename = vim.uri_to_fname(result.location.uri)
    local start = result.location.range.start

    vim.cmd('edit ' .. filename)
    vim.api.nvim_win_set_cursor(0, { start.line + 1, start.character })
  end)
end

local function toggle_tracked_test_by_index(index)
  if index > #M.test_tracker then
    index = #M.test_tracker
  end
  local target_test = M.test_tracker[index].test_name
  terminal_multiplexer:toggle_float_terminal(target_test)
end

for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
  map('n', string.format('<leader>%d', idx), function() jump_to_tracked_test_by_index(idx) end, { desc = string.format('Jump to tracked test %d', idx) })
end

for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
  map('n', string.format('<localleader>v%d', idx), function() toggle_tracked_test_by_index(idx) end, { desc = string.format('Toggle tracked test %d', idx) })
end

local function quickfix_load_tracked_tests(test_names)
  local results = {}
  local pending = #test_names

  for _, test in ipairs(test_names) do
    vim.lsp.buf_request(0, 'workspace/symbol', { query = test }, function(err, res)
      pending = pending - 1
      if not err and res then
        vim.list_extend(results, res)
      end

      if pending == 0 then
        if vim.tbl_isempty(results) then
          print 'No test definitions found'
        else
          local qf_items = {}
          for _, symbol in ipairs(results) do
            local filename = vim.uri_to_fname(symbol.location.uri)
            local start = symbol.location.range.start
            table.insert(qf_items, {
              filename = filename,
              lnum = start.line + 1,
              col = start.character + 1,
              text = symbol.name,
            })
          end
          vim.fn.setqflist(qf_items)
          vim.notify('Loaded tracked test in quickfix', vim.log.levels.INFO, { title = 'Tracked Test in Quickfix' })
        end
      end
    end)
  end
end

vim.api.nvim_create_user_command('QuickfixLoadTrackedTest', function()
  local test_names = {}
  for _, test_info in ipairs(M.test_tracker) do
    table.insert(test_names, test_info.test_name)
  end
  quickfix_load_tracked_tests(test_names)
end, {})

-- Optional: Map a key sequence to start the command (you'll need to type the test name after the command)
vim.api.nvim_set_keymap('n', '<localleader>g', ':GoToTest ', { noremap = true, silent = false })

M.view_tracker = -1

local function toggle_view_enclosing_test()
  local needs_open = true
  for test_name, _ in pairs(terminal_multiplexer.all_terminals) do
    local current_floating_term_state = terminal_multiplexer.all_terminals[test_name]
    if current_floating_term_state then
      if vim.api.nvim_win_is_valid(current_floating_term_state.win) then
        vim.api.nvim_win_hide(current_floating_term_state.win)
        vim.api.nvim_win_hide(current_floating_term_state.footer_win)
        needs_open = false
      end
    end
  end

  if needs_open then
    local test_name = Get_enclosing_test()
    assert(test_name, 'No test found')
    local float_terminal_state = terminal_multiplexer:toggle_float_terminal(test_name)
    assert(float_terminal_state, 'Failed to create floating terminal')

    -- Need this duplication. Otherwise, the keymap is bind to the buffer for for some reason
    local close_term = function()
      if vim.api.nvim_win_is_valid(float_terminal_state.footer_win) then
        vim.api.nvim_win_hide(float_terminal_state.footer_win)
      end
      if vim.api.nvim_win_is_valid(float_terminal_state.win) then
        vim.api.nvim_win_hide(float_terminal_state.win)
      end
    end
    vim.keymap.set('n', 'q', close_term, { buffer = float_terminal_state.buf })
  end
end

---@param test_info testInfo
local go_test_command = function(test_info)
  assert(test_info.test_name, 'No test found')
  assert(test_info.test_bufnr, 'No test buffer found')
  assert(test_info.test_line, 'No test line found')
  assert(test_info.test_command, 'No test command found')
  assert(vim.api.nvim_buf_is_valid(test_info.test_bufnr), 'Invalid buffer')
  local test_name = test_info.test_name
  local test_line = test_info.test_line
  local test_command = test_info.test_command
  local source_bufnr = test_info.test_bufnr
  terminal_multiplexer:toggle_float_terminal(test_name)
  local float_term_state = terminal_multiplexer:toggle_float_terminal(test_name)
  assert(float_term_state, 'Failed to create floating terminal')
  vim.api.nvim_chan_send(float_term_state.chan, test_command .. '\n')

  local notification_sent = false
  vim.api.nvim_buf_attach(float_term_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)
      local current_time = os.date '%H:%M:%S'
      local error_line

      for _, line in ipairs(lines) do
        if string.match(line, '--- FAIL') then
          vim.api.nvim_buf_set_extmark(source_bufnr, ns, test_line - 1, 0, {
            virt_text = { { string.format('❌ %s', current_time) } },
            virt_text_pos = 'eol',
          })
          test_info.status = 'failed'
          float_term_state.status = 'failed'

          make_notify(string.format('Test failed: %s', test_name))
          notification_sent = true
          return true
        elseif string.match(line, '--- PASS') then
          vim.api.nvim_buf_set_extmark(source_bufnr, ns, test_line - 1, 0, {
            virt_text = { { string.format('✅ %s', current_time) } },
            virt_text_pos = 'eol',
          })
          test_info.status = 'passed'
          float_term_state.status = 'passed'

          if not notification_sent then
            make_notify(string.format('Test passed: %s', test_name))
            notification_sent = true
            return true -- detach from the buffer
          end
        end

        -- Pattern matches strings like "Error Trace:    /Users/path/file.go:21"
        local file, line_num = string.match(line, 'Error Trace:%s+([^:]+):(%d+)')

        if file and line_num then
          error_line = tonumber(line_num)

          -- Try to find the buffer for this file
          local error_bufnr
          for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
            local buf_name = vim.api.nvim_buf_get_name(buf_id)
            if buf_name:match(file .. '$') then
              error_bufnr = buf_id
              break
            end
          end

          if error_bufnr then
            vim.fn.sign_define('GoTestError', { text = '✗', texthl = 'DiagnosticError' })
            vim.fn.sign_place(0, 'GoTestErrorGroup', 'GoTestError', error_bufnr, { lnum = error_line })
          end
        end
      end

      -- Only detach if we're done processing (when test is complete)
      if notification_sent and error_line then
        return true
      end

      return false
    end,
  })
end

local function test_buf(test_format)
  local source_bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(source_bufnr)
  for test_name, test_line in pairs(testsInCurrBuf) do
    terminal_multiplexer:delete_terminal(test_name)
    local test_command = string.format(test_format, test_name)
    local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
    make_notify(string.format('Running test: %s', test_name))
    for index, existing_test_info in ipairs(M.test_tracker) do
      if existing_test_info.test_name == test_info.test_name then
        M.test_tracker[index] = test_info
      end
    end
    go_test_command(test_info)
  end
end

local function get_test_info_enclosing_test()
  local test_name, test_line = Get_enclosing_test()
  if not test_name then
    make_notify 'No test found'
    return nil
  end

  local test_command
  if vim.fn.has 'win32' == 1 then
    test_command = string.format('gitBash -c "go test ./... -v -race -run %s"\r', test_name)
  else
    test_command = string.format('go test integration_tests/*.go -v -run %s', test_name)
  end
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
  return test_info
end

---@return  testInfo | nil
local function go_integration_test()
  local test_info = get_test_info_enclosing_test()
  if not test_info then
    return nil
  end
  terminal_multiplexer:delete_terminal(test_info.test_name)
  go_test_command(test_info)
  make_notify(string.format('Running test: %s', test_info.test_name))
  return test_info
end

local function drive_test_dev()
  vim.env.MODE, vim.env.UKS = 'dev', 'others'
  go_integration_test()
end

local function drive_test_staging()
  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  go_integration_test()
end

local function windows_test_buf()
  local test_format = 'gitBash -c "go test ./... -v -race -run %s"\r'
  test_buf(test_format)
end

local function drive_test_dev_buf()
  vim.env.MODE, vim.env.UKS = 'dev', 'others'
  local test_format = 'go test integration_tests/*.go -v -run %s'
  test_buf(test_format)
end

local function drive_test_staging_buf()
  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  local test_format = 'go test integration_tests/*.go -v -run %s'
  test_buf(test_format)
end

local go_normal_test = function()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  terminal_multiplexer:delete_terminal(test_name)
  assert(test_name, 'No test found')
  local test_command = string.format('go test ./... -v -run %s\r\n', test_name)
  local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
  go_test_command(test_info)
end

local function test_normal_buf()
  local test_format = 'go test ./... -v -run %s'
  test_buf(test_format)
end

local function test_normal_tracked()
  local test_format = 'go test ./... -v -run %s'
  for _, test_info in ipairs(M.test_tracker) do
    test_info.test_command = string.format(test_format, test_info.test_name)
    go_test_command(test_info)
  end
end

vim.api.nvim_create_user_command('GoTestNormalTracked', test_normal_tracked, {})

--- === Test List ===

M.test_track = function()
  for _, test_info in ipairs(M.test_tracker) do
    make_notify(string.format('Running test: %s', test_info.test_name))
    go_test_command(test_info)
  end
end

local function delete_test_terminal()
  local test_name, _ = Get_enclosing_test()
  if not test_name then
    make_notify 'No test found'
    return
  end
  for index, test_info in ipairs(M.test_tracker) do
    if test_info.test_name == test_name then
      table.remove(M.test_tracker, index)
      break
    end
  end
  terminal_multiplexer:delete_terminal(test_name)
  make_notify(string.format('Deleted test terminal from tracker: %s', test_name))
end

local function add_test_to_tracker()
  local test_info = get_test_info_enclosing_test()
  if not test_info then
    return nil
  end
  for _, existing_test_info in ipairs(M.test_tracker) do
    if existing_test_info.test_name == test_info.test_name then
      make_notify(string.format('Test already in tracker: %s', test_info.test_name))
      return
    end
  end
  table.insert(M.test_tracker, test_info)
end

local function view_tests_tracked()
  if vim.api.nvim_win_is_valid(M.view_tracker) then
    vim.api.nvim_win_close(M.view_tracker, true)
    return
  end

  local all_tracked_tests = { '', '' }

  for _, test_info in ipairs(M.test_tracker) do
    if test_info.status == 'failed' then
      table.insert(all_tracked_tests, '\t' .. '❌' .. '  ' .. test_info.test_name)
    elseif test_info.status == 'passed' then
      table.insert(all_tracked_tests, '\t' .. '✅' .. '  ' .. test_info.test_name)
    else
      table.insert(all_tracked_tests, '\t' .. '⏳' .. '  ' .. test_info.test_name)
    end
  end

  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.3)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, all_tracked_tests)
  M.view_tracker = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = 'Go Test Tracker',
    title_pos = 'center',
  })
  vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(M.view_tracker, true) end, { buffer = buf })
end

vim.api.nvim_create_user_command('GoTestViewTracked', view_tests_tracked, {})
vim.api.nvim_create_user_command('GoTestDriveStagingBuf', drive_test_staging_buf, {})
vim.api.nvim_create_user_command('GoTestDriveDevBuf', drive_test_dev_buf, {})
vim.api.nvim_create_user_command('GoTestWindowsBuf', windows_test_buf, {})
vim.api.nvim_create_user_command('GoTestDriveDev', drive_test_dev, {})
vim.api.nvim_create_user_command('GoTestDriveStaging', drive_test_staging, {})

vim.api.nvim_create_user_command('GoTestIntegration', go_integration_test, {})
vim.api.nvim_create_user_command('GoTestTrack', M.test_track, {})
vim.api.nvim_create_user_command('GoTestReset', function() M.reset_test() end, {})
vim.api.nvim_create_user_command('GoTestSearch', function() terminal_multiplexer:search_terminal() end, {})
vim.api.nvim_create_user_command('GoTestDelete', function() terminal_multiplexer:select_delete_terminal() end, {})

vim.api.nvim_create_user_command('GoTestNormalBuf', test_normal_buf, {})
vim.api.nvim_create_user_command('GoTestNormal', go_normal_test, {})

vim.keymap.set('n', '<leader>st', function() terminal_multiplexer:search_terminal() end, { desc = 'Select test terminal' })
vim.keymap.set('n', '<leader>tf', function() terminal_multiplexer:search_terminal(true) end, { desc = 'Select test terminal with pass filter' })
vim.keymap.set('n', '<leader>tg', toggle_view_enclosing_test, { desc = 'Toggle go test terminal' })

vim.keymap.set('n', '<leader>tl', function ()
  terminal_multiplexer:toggle_float_terminal(terminal_multiplexer.last_terminal_name)
end, { desc = 'Toggle last go test terminal' })

vim.keymap.set('n', '<leader>at', add_test_to_tracker, { desc = '[A]dd [T]est to tracker' })
vim.keymap.set('n', '<leader>dt', delete_test_terminal, { desc = '[D]elete [T]est terminal' })

vim.keymap.set('n', '<leader>G', go_integration_test, { desc = 'Go integration test' })

return M
