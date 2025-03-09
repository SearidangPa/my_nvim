local M = {}
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local ns_name = 'push_flow'
local ns = vim.api.nvim_create_namespace(ns_name)

local current_float_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
  footer_buf = -1,
  footer_win = -1,
}

local function create_float_window(floating_term_state, term_name)
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
  local padding = string.rep(' ', width - #term_name - 1)
  local footer_text = padding .. term_name
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
local toggle_float_terminal = function(test_name)
  assert(test_name, 'test_name is required')

  current_float_term_state = M.all_daemons_term[test_name]
  if not current_float_term_state then
    current_float_term_state = {
      buf = -1,
      win = -1,
      chan = 0,
      footer_buf = -1,
      footer_win = -1,
    }
    M.all_daemons_term[test_name] = current_float_term_state
  end
  if not vim.tbl_contains(M.test_terminal_order, test_name) then
    table.insert(M.test_terminal_order, test_name)
  end

  if vim.api.nvim_win_is_valid(current_float_term_state.win) then
    vim.api.nvim_win_hide(current_float_term_state.win)
    vim.api.nvim_win_hide(current_float_term_state.footer_win)
    return
  end

  create_float_window(current_float_term_state, test_name)
  if vim.bo[current_float_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    current_float_term_state.chan = vim.bo.channel
  end

  -- Set up navigation keys for this buffer
  vim.api.nvim_buf_set_keymap(
    current_float_term_state.buf,
    'n',
    '>',
    '<cmd>lua require("config.go_test").navigate_test_terminal(1)<CR>',
    { noremap = true, silent = true, desc = 'Next test terminal' }
  )
  vim.api.nvim_buf_set_keymap(
    current_float_term_state.buf,
    'n',
    '<',
    '<cmd>lua require("config.go_test").navigate_test_terminal(-1)<CR>',
    { noremap = true, silent = true, desc = 'Previous test terminal' }
  )
  vim.api.nvim_buf_set_keymap(current_float_term_state.buf, 'n', 'q', '<cmd>q<CR>', { noremap = true, silent = true, desc = 'Previous test terminal' })
end

M.reset = function()
  for test_name, _ in pairs(M.all_daemons_term) do
    current_float_term_state = M.all_daemons_term[test_name]
    if current_float_term_state then
      vim.api.nvim_chan_send(current_float_term_state.chan, 'clear\n')
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

local exec_command = function(source_bufnr, command, title)
  toggle_float_terminal(title)
  toggle_float_terminal(title)
  vim.api.nvim_chan_send(current_float_term_state.chan, command .. '\n')
  make_notify(string.format('running %s', title))
  local notification_sent = false

  vim.api.nvim_buf_attach(current_float_term_state.buf, false, {
    on_lines = function(_, buf, _, first_line, last_line)
      local lines = vim.api.nvim_buf_get_lines(buf, first_line, last_line, false)
      local current_time = os.date '%H:%M:%S'
      local error_file
      local error_line

      for _, line in ipairs(lines) do
        if string.match(line, '--- FAIL') then
          make_notify(string.format('%s failed', title))
          notification_sent = true
          return true
        elseif string.match(line, '--- PASS') then
          if not notification_sent then
            make_notify(string.format('%s passed', title))
            notification_sent = true
            return true -- detach from the buffer
          end
        end
      end

      return false
    end,
  })
end

local function search_daemon_term()
  local opts = {
    prompt = 'Select daemon terminal:',
    format_item = function(item)
      return item
    end,
  }

  local all_test_names = {}
  for test_name, _ in pairs(M.all_daemons_term) do
    current_float_term_state = M.all_daemons_term[test_name]
    if current_float_term_state then
      table.insert(all_test_names, test_name)
    end
  end
  local handle_choice = function(test_name)
    toggle_float_terminal(test_name)
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
  for test_name, state in pairs(M.all_daemons_term) do
    if state.buf == current_buf then
      current_test_name = test_name
      break
    end
  end

  if not current_test_name then
    -- If we're not in a test terminal, just open the first one
    toggle_float_terminal(M.test_terminal_order[1])
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
  if vim.api.nvim_win_is_valid(current_float_term_state.win) then
    vim.api.nvim_win_hide(current_float_term_state.win)
    vim.api.nvim_win_hide(current_float_term_state.footer_win)
  end

  toggle_float_terminal(next_test_name)
end

-- === Commands and keymaps ===
vim.api.nvim_create_user_command('RunDaemon', function()
  exec_command(0, 'dr;rds', 'run drive daemon')
end, {})

vim.keymap.set('n', '<leader>sd', search_daemon_term, { desc = 'Select test terminal' })

return M
