local M = {}
require 'config.util_find_func'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local ns_name = 'live_go_test_ns'
local ns = vim.api.nvim_create_namespace(ns_name)
vim.cmd [[highlight TestNameUnderlined gui=underline]]

M.all_tests_term = {}

---@class Float_Term_State
---@field buf number
---@field win number
---@field chan number
---@field footer_buf number
---@field footer_win number

local current_floating_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
  footer_buf = -1,
  footer_win = -1,
}

---@param floating_term_state Float_Term_State
local function create_test_floating_window(floating_term_state, test_name)
  local buf_input = floating_term_state.buf or -1
  local width = math.floor(vim.o.columns)
  local height = math.floor(vim.o.lines)
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
    height = height - 2,
    row = row,
    col = col,
    style = 'minimal',
    border = 'none',
  })

  local footer_buf = vim.api.nvim_create_buf(false, true)
  local padding = string.rep(' ', width - #test_name - 1)
  local footer_text = padding .. test_name
  vim.api.nvim_buf_set_lines(footer_buf, 0, -1, false, { footer_text })
  vim.api.nvim_buf_add_highlight(footer_buf, -1, 'Title', 0, 0, -1)

  vim.api.nvim_buf_add_highlight(footer_buf, -1, 'TestNameUnderlined', 0, #padding, -1)

  vim.api.nvim_win_call(win, function()
    vim.cmd 'normal! G'
  end)

  local footer_win = vim.api.nvim_open_win(footer_buf, false, {
    relative = 'win',
    width = width,
    height = 1,
    row = height - 1,
    col = 0,
    style = 'minimal',
    border = 'none',
  })

  floating_term_state.buf = buf
  floating_term_state.win = win
  floating_term_state.footer_buf = footer_buf
  floating_term_state.footer_win = footer_win
end

---@param test_name string
local toggle_test_floating_terminal = function(test_name)
  if not test_name then
    return
  end

  current_floating_term_state = M.all_tests_term[test_name]
  if not current_floating_term_state then
    current_floating_term_state = {
      buf = -1,
      win = -1,
      chan = 0,
      footer_buf = -1,
      footer_win = -1,
    }
    M.all_tests_term[test_name] = current_floating_term_state
  end
  if not vim.tbl_contains(M.test_terminal_order, test_name) then
    table.insert(M.test_terminal_order, test_name)
  end

  if vim.api.nvim_win_is_valid(current_floating_term_state.win) then
    vim.api.nvim_win_hide(current_floating_term_state.win)
    vim.api.nvim_win_hide(current_floating_term_state.footer_win)
    return
  end

  create_test_floating_window(current_floating_term_state, test_name)
  if vim.bo[current_floating_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    current_floating_term_state.chan = vim.bo.channel
  end

  -- Set up navigation keys for this buffer
  vim.api.nvim_buf_set_keymap(
    current_floating_term_state.buf,
    'n',
    '>',
    '<cmd>lua require("config.go_test").navigate_test_terminal(1)<CR>',
    { noremap = true, silent = true, desc = 'Next test terminal' }
  )
  vim.api.nvim_buf_set_keymap(
    current_floating_term_state.buf,
    'n',
    '<',
    '<cmd>lua require("config.go_test").navigate_test_terminal(-1)<CR>',
    { noremap = true, silent = true, desc = 'Previous test terminal' }
  )
  vim.api.nvim_buf_set_keymap(current_floating_term_state.buf, 'n', 'q', '<cmd>q<CR>', { noremap = true, silent = true, desc = 'Previous test terminal' })
end

M.reset = function()
  for test_name, _ in pairs(M.all_tests_term) do
    current_floating_term_state = M.all_tests_term[test_name]
    if current_floating_term_state then
      vim.api.nvim_chan_send(current_floating_term_state.chan, 'clear\n')
    end
  end

  for _, buf_id in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(buf_id) then
      vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
      vim.fn.sign_unplace('GoTestErrorGroup', { buffer = buf_id })
    end
  end
  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
end

local go_test_command = function(source_bufnr, test_name, test_line, test_command)
  test_command = test_command or string.format('go test .\\... -v -run %s\r\n', test_name)

  make_notify(string.format('running test: %s', test_name))

  toggle_test_floating_terminal(test_name)
  toggle_test_floating_terminal(test_name)

  vim.api.nvim_chan_send(current_floating_term_state.chan, test_command .. '\n')
  local notification_sent = false

  vim.api.nvim_buf_attach(current_floating_term_state.buf, false, {
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

          make_notify(string.format('Test failed: %s', test_name))
          notification_sent = true
          return true
        elseif string.match(line, '--- PASS') then
          vim.api.nvim_buf_set_extmark(source_bufnr, ns, test_line - 1, 0, {
            virt_text = { { string.format('✅ %s', current_time) } },
            virt_text_pos = 'eol',
          })

          if not notification_sent then
            make_notify(string.format('Test passed: %s', test_name))
            notification_sent = true
            return true -- detach from the buffer
          end
        end

        -- Parse error trace information
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

        -- Also look for more specific errors like "assert failed" with line information
        local assertion_file, assertion_line = string.match(line, 'assert%s+failed%s+at%s+([^:]+):(%d+)')
        if assertion_file and assertion_line then
          print('assertion failed', assertion_file, assertion_line)
          -- Similar code to mark the specific assertion failure
          -- (implementation similar to above)
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

local function drive_test_dev()
  vim.env.MODE, vim.env.UKS = 'dev', 'others'
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  local test_command = string.format('go test integration_tests/*.go -v -run %s', test_name)
  go_test_command(source_bufnr, test_name, test_line, test_command)
end

local function drive_test_staging()
  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  local test_command = string.format('go test integration_tests/*.go -v -run %s', test_name)
  go_test_command(source_bufnr, test_name, test_line, test_command)
end

local windows_test_this = function()
  M.reset()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  local test_command = string.format('gitBash -c "go test integration_tests/*.go -v -race -run %s"\r', test_name)
  go_test_command(source_bufnr, test_name, test_line, test_command)
end

local go_test = function()
  M.reset()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  local test_command = string.format('go test ./... -v -run %s\r\n', test_name)
  go_test_command(source_bufnr, test_name, test_line, test_command)
end

local function test_buf(test_format)
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  M.reset()
  for test_name, test_line in pairs(testsInCurrBuf) do
    local test_command = string.format(test_format, test_name)
    go_test_command(bufnr, test_name, test_line, test_command)
  end
end

local function test_all()
  local test_format = 'go test ./... -v -run %s'
  test_buf(test_format)
end

local function drive_test_all_staging()
  vim.env.MODE, vim.env.UKS = 'staging', 'others'
  local test_format = 'go test integration_tests/*.go -v -run %s'
  test_buf(test_format)
end

local function drive_test_all_dev()
  vim.env.MODE, vim.env.UKS = 'dev', 'others'
  local test_format = 'go test integration_tests/*.go -v -run %s'
  test_buf(test_format)
end

local function windows_test_all()
  local test_format = 'gitBash -c "go test integration_tests/*.go -v -race -run %s"\r'
  test_buf(test_format)
end

--- === View test terminal ===

local function toggle_view_enclosing_test()
  local needs_open = true

  for test_name, _ in pairs(M.all_tests_term) do
    current_floating_term_state = M.all_tests_term[test_name]
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
    toggle_test_floating_terminal(test_name)
  end
end

local function search_test_term()
  local opts = {
    prompt = 'Select test terminal:',
    format_item = function(item)
      return item
    end,
  }

  local all_test_names = {}
  for test_name, _ in pairs(M.all_tests_term) do
    current_floating_term_state = M.all_tests_term[test_name]
    if current_floating_term_state then
      table.insert(all_test_names, test_name)
    end
  end
  local handle_choice = function(test_name)
    toggle_test_floating_terminal(test_name)
  end

  vim.ui.select(all_test_names, opts, function(choice)
    handle_choice(choice)
  end)
end

--- === Navigate between test terminals ===;
M.test_terminal_order = {} -- To keep track of the order of terminals

---@param direction number 1 for next, -1 for previous
M.navigate_test_terminal = function(direction)
  if #M.test_terminal_order == 0 then
    vim.notify('No test terminals available', vim.log.levels.INFO)
    return
  end

  -- Find the current buffer
  local current_buf = vim.api.nvim_get_current_buf()
  local current_test_name = nil

  -- Find which test terminal we're currently in
  for test_name, state in pairs(M.all_tests_term) do
    if state.buf == current_buf then
      current_test_name = test_name
      break
    end
  end

  if not current_test_name then
    -- If we're not in a test terminal, just open the first one
    toggle_test_floating_terminal(M.test_terminal_order[1])
    return
  end

  -- Find the index of the current terminal
  local current_index = nil
  for i, name in ipairs(M.test_terminal_order) do
    if name == current_test_name then
      current_index = i
      break
    end
  end

  if not current_index then
    -- This shouldn't happen, but just in case
    vim.notify('Current test terminal not found in order list', vim.log.levels.ERROR)
    return
  end

  -- Calculate the next index with wrapping
  local next_index = ((current_index - 1 + direction) % #M.test_terminal_order) + 1
  local next_test_name = M.test_terminal_order[next_index]

  -- Hide current terminal and show the next one
  if vim.api.nvim_win_is_valid(current_floating_term_state.win) then
    vim.api.nvim_win_hide(current_floating_term_state.win)
    vim.api.nvim_win_hide(current_floating_term_state.footer_win)
  end

  toggle_test_floating_terminal(next_test_name)
end

local delete_test_term = function()
  local opts = {
    prompt = 'Select test terminal:',
    format_item = function(item)
      return item
    end,
  }

  local all_test_names = {}
  for test_name, _ in pairs(M.all_tests_term) do
    current_floating_term_state = M.all_tests_term[test_name]
    if current_floating_term_state then
      table.insert(all_test_names, test_name)
    end
  end
  local handle_choice = function(test_name)
    local float_test_term = M.all_tests_term[test_name]
    vim.api.nvim_buf_delete(float_test_term.buf, { force = true })
    M.all_tests_term[test_name] = nil
    for i, name in ipairs(M.test_terminal_order) do
      if name == test_name then
        table.remove(M.test_terminal_order, i)
        break
      end
    end
  end

  vim.ui.select(all_test_names, opts, function(choice)
    handle_choice(choice)
  end)
end

-- === Commands and keymaps ===

vim.api.nvim_create_user_command('GoTestDriveAllStaging', drive_test_all_staging, {})
vim.api.nvim_create_user_command('GoTestDriveAllDev', drive_test_all_dev, {})
vim.api.nvim_create_user_command('GoTestAllWindows', windows_test_all, {})
vim.api.nvim_create_user_command('GoTestAll', test_all, {})
vim.api.nvim_create_user_command('GoTestReset', M.reset, {})
vim.api.nvim_create_user_command('GoTest', go_test, {})
vim.api.nvim_create_user_command('GoTestWindows', windows_test_this, {})
vim.api.nvim_create_user_command('GoTestDriveDev', drive_test_dev, {})
vim.api.nvim_create_user_command('GoTestDriveStaging', drive_test_staging, {})

vim.keymap.set('n', '<leader>gt', toggle_view_enclosing_test, { desc = 'Toggle go test terminal' })
vim.keymap.set('n', '<leader>st', search_test_term, { desc = 'Select test terminal' })
vim.keymap.set('n', '<leader>dt', delete_test_term, { desc = '[D]elete [T]est terminal' })
return M
