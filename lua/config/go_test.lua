local M = {}
require 'config.util_find_func'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

M.all_tests_term = {}

local floating_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
}

local function create_test_floating_window(buf_input)
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

---@param test_name string
local toggle_test_floating_terminal = function(test_name)
  assert(test_name, 'test_name is required')

  floating_term_state = M.all_tests_term[test_name]
  if not floating_term_state then
    floating_term_state = {
      buf = -1,
      win = -1,
      chan = 0,
    }
    M.all_tests_term[test_name] = floating_term_state
  end

  if vim.api.nvim_win_is_valid(floating_term_state.win) then
    vim.api.nvim_win_hide(floating_term_state.win)
    return
  end

  floating_term_state.buf, floating_term_state.win = create_test_floating_window(floating_term_state.buf)
  if vim.bo[floating_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    floating_term_state.chan = vim.bo.channel
  end
end

local ns_name = 'live_go_test_ns'
local ns = vim.api.nvim_create_namespace(ns_name)

local test = function(source_bufnr, test_name, test_line, test_command)
  test_command = test_command or string.format('go test .\\... -v -run %s', test_name)

  make_notify(string.format('running test: %s', test_name))

  toggle_test_floating_terminal(test_name)
  toggle_test_floating_terminal(test_name)

  vim.api.nvim_chan_send(floating_term_state.chan, test_command .. '\n')
  local notification_sent = false

  vim.api.nvim_buf_attach(floating_term_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)

      local current_time = os.date '%H:%M:%S'
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
      end

      return false
    end,
  })
end

local go_test = function(test_format)
  M.reset()
  local source_bufnr = vim.api.nvim_get_current_buf()
  local test_name, test_line = Get_enclosing_test()
  local test_command = string.format(test_format, test_name)
  test(source_bufnr, test_name, test_line, test_command)
end

local function drive_test_dev()
  vim.env.UKS = 'others'
  vim.env.MODE = 'dev'
  local test_command = 'go test integration_tests/*.go -v -run %s'
  go_test(test_command)
end

local function drive_test_staging()
  vim.env.UKS = 'others'
  vim.env.MODE = 'staging'
  local test_command = 'go test integration_tests/*.go -v -run %s'
  go_test(test_command)
end

local function drive_test_buf()
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  M.reset()
  local test_command = 'go test integration_tests/*.go -v -run %s'
  for test_name, test_line in pairs(testsInCurrBuf) do
    test(bufnr, test_name, test_line, test_command)
  end
end

local function drive_test_all_staging()
  vim.env.UKS = 'others'
  vim.env.MODE = 'staging'
  drive_test_buf()
end

local function drive_test_all_dev()
  vim.env.UKS = 'others'
  vim.env.MODE = 'dev'
  drive_test_buf()
end

--- reset all tests terminal
M.reset = function()
  for test_name, _ in pairs(M.all_tests_term) do
    floating_term_state = M.all_tests_term[test_name]
    if floating_term_state then
      vim.api.nvim_chan_send(floating_term_state.chan, 'clear\n')
    end
  end
  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
end

local function toggle_view_enclosing_test()
  local needs_open = true

  for test_name, _ in pairs(M.all_tests_term) do
    floating_term_state = M.all_tests_term[test_name]
    if floating_term_state then
      if vim.api.nvim_win_is_valid(floating_term_state.win) then
        vim.api.nvim_win_hide(floating_term_state.win)
        needs_open = false
      end
    end
  end

  if needs_open then
    local test_name = Get_enclosing_test()
    toggle_test_floating_terminal(test_name)
  end
end

vim.api.nvim_create_user_command('GoTestAllStaging', drive_test_all_staging, {})
vim.api.nvim_create_user_command('GoTestAllDev', drive_test_all_dev, {})
vim.api.nvim_create_user_command('GoTest', go_test, {})
vim.api.nvim_create_user_command('GoTestDev', drive_test_dev, {})
vim.api.nvim_create_user_command('GOTestStaging', drive_test_staging, {})

vim.keymap.set('n', '<leader>gt', toggle_view_enclosing_test, { desc = 'Toggle go test terminal' })

--TODO: Wire telescope to select which test terminal to open

return M
