-- terminal_multiplexer.lua
local TerminalMultiplexer = {}
TerminalMultiplexer.__index = TerminalMultiplexer

---@class TerminalMultiplexer
---@field all_terminals table<string, Float_Term_State>
---@field terminal_order string[]

-- Constructor for the TerminalMultiplexer
-- @return TerminalMultiplexer
function TerminalMultiplexer.new()
  local self = setmetatable({}, TerminalMultiplexer)
  self.all_terminals = {}
  self.terminal_order = {} -- To keep track of the order of terminals
  return self
end

---@class Float_Term_State
---@field buf number
---@field win number
---@field chan number
---@field footer_buf number
---@field footer_win number

function TerminalMultiplexer:search_test_term()
  local opts = {
    prompt = 'Select test terminal:',
    format_item = function(item)
      return item
    end,
  }

  local all_test_names = {}
  for test_name, _ in pairs(self.all_terminals) do
    local term_state = self.all_terminals[test_name]
    if term_state then
      table.insert(all_test_names, test_name)
    end
  end

  local handle_choice = function(test_name)
    self:toggle_test_floating_terminal(test_name)
  end

  vim.ui.select(all_test_names, opts, function(choice)
    handle_choice(choice)
  end)
end

function TerminalMultiplexer:delete_test_term()
  local opts = {
    prompt = 'Select test terminal:',
    format_item = function(item)
      return item
    end,
  }

  local all_test_names = {}
  for test_name, _ in pairs(self.all_terminals) do
    local term_state = self.all_terminals[test_name]
    if term_state then
      table.insert(all_test_names, test_name)
    end
  end

  local handle_choice = function(test_name)
    local float_test_term = self.all_terminals[test_name]
    vim.api.nvim_buf_delete(float_test_term.buf, { force = true })
    self.all_terminals[test_name] = nil
    for i, name in ipairs(self.terminal_order) do
      if name == test_name then
        table.remove(self.terminal_order, i)
        break
      end
    end
  end

  vim.ui.select(all_test_names, opts, function(choice)
    handle_choice(choice)
  end)
end

--- === Navigate between test terminals ===;
---@param direction number 1 for next, -1 for previous
function TerminalMultiplexer:navigate_terminal(direction)
  if #self.terminal_order == 0 then
    vim.notify('No test terminals available', vim.log.levels.INFO)
    return
  end

  -- Find the current buffer
  local current_buf = vim.api.nvim_get_current_buf()
  local current_test_name = nil

  -- Find which test terminal we're currently in
  for test_name, state in pairs(self.all_terminals) do
    if state.buf == current_buf then
      current_test_name = test_name
      break
    end
  end

  if not current_test_name then
    -- If we're not in a test terminal, just open the first one
    self:toggle_test_floating_terminal(self.terminal_order[1])
    return
  end

  -- Find the index of the current terminal
  local current_index = nil
  for i, name in ipairs(self.terminal_order) do
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
  local next_index = ((current_index - 1 + direction) % #self.terminal_order) + 1
  local next_test_name = self.terminal_order[next_index]

  -- Hide current terminal and show the next one
  local current_term_state = self.all_terminals[current_test_name]
  if vim.api.nvim_win_is_valid(current_term_state.win) then
    vim.api.nvim_win_hide(current_term_state.win)
    vim.api.nvim_win_hide(current_term_state.footer_win)
  end

  self:toggle_test_floating_terminal(next_test_name)
end

---@param floating_term_state Float_Term_State
function TerminalMultiplexer:create_test_floating_window(floating_term_state, test_name)
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

  local map_opts = { noremap = true, silent = true, buffer = buf }

  local terminal_multiplexer = self -- capture self in closure
  local next_term = function()
    terminal_multiplexer:navigate_terminal(1)
  end
  local prev_term = function()
    terminal_multiplexer:navigate_terminal(-1)
  end
  vim.keymap.set('n', 'q', '<cmd>q<CR>', map_opts)
  vim.keymap.set('n', '>', next_term, map_opts)
  vim.keymap.set('n', '<', prev_term, map_opts)
end

---@param test_name string
---@param ensure_open boolean|nil If true, always ensure the terminal is open
---@return table | nil
function TerminalMultiplexer:toggle_test_floating_terminal(test_name, ensure_open)
  if not test_name then
    return nil
  end

  local current_floating_term_state = self.all_terminals[test_name]
  if not current_floating_term_state then
    current_floating_term_state = {
      buf = -1,
      win = -1,
      chan = 0,
      footer_buf = -1,
      footer_win = -1,
    }
    self.all_terminals[test_name] = current_floating_term_state
  end

  if not vim.tbl_contains(self.terminal_order, test_name) then
    table.insert(self.terminal_order, test_name)
  end

  local is_visible = vim.api.nvim_win_is_valid(current_floating_term_state.win)

  if is_visible then
    vim.api.nvim_win_hide(current_floating_term_state.win)
    vim.api.nvim_win_hide(current_floating_term_state.footer_win)
    return self.all_terminals[test_name]
  else
    self:create_test_floating_window(current_floating_term_state, test_name)
    if vim.bo[current_floating_term_state.buf].buftype ~= 'terminal' then
      if vim.fn.has 'win32' == 1 then
        vim.cmd.term 'powershell.exe'
      else
        vim.cmd.term()
      end
      current_floating_term_state.chan = vim.bo.channel
    end
  end

  return self.all_terminals[test_name]
end

function TerminalMultiplexer:reset()
  for test_name, _ in pairs(self.all_terminals) do
    local term_state = self.all_terminals[test_name]
    if term_state then
      vim.api.nvim_chan_send(term_state.chan, 'clear\n')
    end
  end

  vim.api.nvim_buf_clear_namespace(0, -1, 0, -1)
end

return TerminalMultiplexer
