local M = {}
require 'config.util_find_func'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local ns = vim.api.nvim_create_namespace 'GoTestError'

---@class testInfo
---@field test_name string
---@field test_line number
---@field test_bufnr number
---@field test_command string
---@field status string

M.test_tracker = {}
M.view_tracker = -1

local TerminalMultiplexer = require 'config.terminal_multiplexer'
local terminal_multiplexer = TerminalMultiplexer.new()

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
      local error_file
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
          error_file = file
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

--- === All Tests in Buffer ===
local function test_buf(test_format)
  local source_bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(source_bufnr)
  for test_name, test_line in pairs(testsInCurrBuf) do
    terminal_multiplexer:reset_terminal(test_name)
    local test_command = string.format(test_format, test_name)
    local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
    make_notify(string.format('Running test: %s', test_name))
    go_test_command(test_info)
    M.test_tracker[test_name] = test_info
  end
end

--- === Drive Test ===
local function drive_test_dev()
  vim.env.MODE, vim.env.UKS = 'dev', 'others'
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  assert(test_name, 'No test found')
  local test_command = string.format('go test integration_tests/*.go -v -run %s', test_name)
  local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
  make_notify(string.format('Running dev test: %s', test_name))
  go_test_command(test_info)
  M.test_tracker[test_name] = test_info
end

local function drive_test_staging()
  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  assert(test_name, 'No test found')
  local test_command = string.format('go test integration_tests/*.go -v -run %s', test_name)
  local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
  make_notify(string.format('Running staging test: %s', test_name))
  go_test_command(test_info)
  M.test_tracker[test_name] = test_info
end

--- === Windows Test ===
local windows_test_this = function()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  assert(test_name, 'No test found')
  terminal_multiplexer:reset_terminal(test_name)
  local test_command = string.format('gitBash -c "go test integration_tests/*.go -v -race -run %s"\r', test_name)
  local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
  make_notify(string.format('Running windows test: %s', test_name))
  go_test_command(test_info)
  M.test_tracker[test_name] = test_info
end

--- === Test All In Buf ===

local function windows_test_all()
  local test_format = 'gitBash -c "go test integration_tests/*.go -v -race -run %s"\r'
  test_buf(test_format)
end

local function drive_test_all_dev()
  vim.env.MODE, vim.env.UKS = 'dev', 'others'
  local test_format = 'go test integration_tests/*.go -v -run %s'
  test_buf(test_format)
end

local function drive_test_all_staging()
  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  local test_format = 'go test integration_tests/*.go -v -run %s'
  test_buf(test_format)
end

-- === Commands and keymaps ===

vim.api.nvim_create_user_command('GoTestDriveAllStaging', drive_test_all_staging, {})
vim.api.nvim_create_user_command('GoTestDriveAllDev', drive_test_all_dev, {})
vim.api.nvim_create_user_command('GoTestAllWindows', windows_test_all, {})
vim.api.nvim_create_user_command('GoTestWindows', windows_test_this, {})
vim.api.nvim_create_user_command('GoTestDriveDev', drive_test_dev, {})
vim.api.nvim_create_user_command('GoTestDriveStaging', drive_test_staging, {})

M.test_list = function()
  for test_name, test_info in pairs(M.test_tracker) do
    go_test_command(test_info)
  end
end

vim.api.nvim_create_user_command('GoTestList', test_list, {})

vim.keymap.set('n', '<leader>lt', test_list, { desc = '[T]est Tracker [L]ist' })
vim.keymap.set('n', '<leader>tg', toggle_view_enclosing_test, { desc = 'Toggle go test terminal' })
vim.keymap.set('n', '<localleader>tw', windows_test_this, { desc = 'Run test in windows' })
vim.keymap.set('n', '<localleader>td', drive_test_staging, { desc = 'Drive test in dev' })

-- stylua: ignore start
vim.api.nvim_create_user_command('GoTestReset', function() terminal_multiplexer:reset_test() end, {})
vim.api.nvim_create_user_command('GoTestSearch', function() terminal_multiplexer:select_terminal() end, {})
vim.api.nvim_create_user_command('GoTestDelete', function() terminal_multiplexer:select_delete_terminal() end, {})
vim.keymap.set('n', '<leader>st', function() terminal_multiplexer:select_terminal() end, { desc = 'Select test terminal' })
-- stylua: ignore end

vim.keymap.set('n', '<leader>dt', function()
  local test_name, test_line = Get_enclosing_test()
  if not test_name then
    make_notify 'No test found'
    return
  end
  M.test_tracker[test_name] = nil
  terminal_multiplexer:delete_terminal(test_name)
  make_notify(string.format('Deleted test terminal from tracker: %s', test_name))
end, { desc = '[D]elete [T]est terminal' })

vim.keymap.set('n', '<leader>gt', function()
  local test_name, test_line = Get_enclosing_test()
  if not test_name then
    make_notify 'No test found'
    return
  end

  local test_command
  if vim.fn.has 'win32' == 1 then
    test_command = string.format('gitBash -c "go test integration_tests/*.go -v -race -run %s"\r', test_name)
  else
    test_command = string.format('go test integration_tests/*.go -v -run %s', test_name)
  end

  terminal_multiplexer:reset_terminal(test_name)
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
  go_test_command(test_info)
  M.test_tracker[test_name] = test_info
  make_notify(string.format('Added test to tracker: %s', test_name))
end, { desc = '[G]o [T]rack test' })

vim.api.nvim_create_user_command('ViewGoTestList', function()
  if vim.api.nvim_win_is_valid(M.view_tracker) then
    vim.api.nvim_win_close(M.view_tracker, true)
    return
  end

  local all_tracked_tests = { '', '' }

  for test_name, test_info in pairs(M.test_tracker) do
    if test_info.status == 'failed' then
      table.insert(all_tracked_tests, '\t' .. '❌' .. '  ' .. test_name)
    elseif test_info.status == 'passed' then
      table.insert(all_tracked_tests, '\t' .. '✅' .. '  ' .. test_name)
    end
  end

  local width = math.floor(vim.o.columns * 0.5)
  local height = math.floor(vim.o.lines * 0.5)
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
end, {})

--- === Go Test ===
local go_test = function()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  terminal_multiplexer:reset_terminal(test_name)
  assert(test_name, 'No test found')
  local test_command = string.format('go test ./... -v -run %s\r\n', test_name)
  local test_info = { test_name = test_name, test_line = test_line, test_bufnr = source_bufnr, test_command = test_command }
  go_test_command(test_info)
  M.test_tracker[test_name] = test_info
end

local function test_all()
  local test_format = 'go test ./... -v -run %s'
  test_buf(test_format)
end

vim.api.nvim_create_user_command('GoTestAll', test_all, {})
vim.api.nvim_create_user_command('GoTest', go_test, {})

return M
