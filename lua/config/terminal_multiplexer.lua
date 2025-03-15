-- terminal_multiplexer.lua
local TerminalMultiplexer = {}
TerminalMultiplexer.__index = TerminalMultiplexer
vim.cmd [[highlight TerminalNameUnderline gui=underline]]

---@class TerminalMultiplexer
---@field all_terminals table<string, Float_Term_State>
---@field terminal_order string[]

---@class Float_Term_State
---@field buf number
---@field win number @field chan number
---@field footer_buf number
---@field footer_win number
---@field chan number
---@field status string

--- === Create, Search, Delete, Navigate between terminals ===;

-- @return TerminalMultiplexer
function TerminalMultiplexer.new()
  local self = setmetatable({}, TerminalMultiplexer)
  self.all_terminals = {} --- @type table<string, Float_Term_State>
  self.terminal_order = {} --- @type string[]
  self.augroup = vim.api.nvim_create_augroup('TerminalMultiplexer', { clear = true }) --- @type number
  return self
end

function TerminalMultiplexer:list()
  local terminal_names = {}
  for terminal_name, _ in pairs(self.all_terminals) do
    table.insert(terminal_names, terminal_name)
  end
  return terminal_names
end

function TerminalMultiplexer:select_terminal(filter_pass)
  local opts = {
    prompt = 'Select terminal:',
    format_item = function(item) return item end,
  }
  --- @type string[]
  local all_terminal_names = {}
  for test_name, terminal_info in pairs(self.all_terminals) do
    if terminal_info.status == 'failed' then
      table.insert(all_terminal_names, '\t' .. '❌' .. '  ' .. test_name)
    elseif terminal_info.status == 'passed' then
      if not filter_pass then
        table.insert(all_terminal_names, '\t' .. '✅' .. '  ' .. test_name)
      end
    else
      table.insert(all_terminal_names, '\t' .. '🔵' .. '  ' .. test_name)
    end
  end
  local handle_choice = function(terminal_name)
    if not terminal_name then
      return
    end
    local terminal_name = terminal_name:match '[\t%s][^\t%s]+[\t%s]+(.+)$'
    self:toggle_float_terminal(terminal_name)
  end

  vim.ui.select(all_terminal_names, opts, function(choice) handle_choice(choice) end)
end

--- === Navigate between terminals ===;
---@param direction number 1 for next, -1 for previous
function TerminalMultiplexer:navigate_terminal(direction)
  if #self.terminal_order == 0 then
    vim.notify('No terminals available', vim.log.levels.INFO)
    return
  end

  -- Find the current buffer
  local current_buf = vim.api.nvim_get_current_buf()
  local current_terminal_name = nil

  -- Find which terminal we're currently in
  for terminal_name, state in pairs(self.all_terminals) do
    if state.buf == current_buf then
      current_terminal_name = terminal_name
      break
    end
  end

  if not current_terminal_name then
    -- If we're not in a terminal, just open the first one
    self:toggle_float_terminal(self.terminal_order[1])
    return
  end

  -- Find the index of the current terminal
  local current_index = nil
  for i, name in ipairs(self.terminal_order) do
    if name == current_terminal_name then
      current_index = i
      break
    end
  end

  if not current_index then
    -- This shouldn't happen, but just in case
    vim.notify('Current terminal not found in order list', vim.log.levels.ERROR)
    return
  end

  -- Calculate the next index with wrapping
  local next_index = ((current_index - 1 + direction) % #self.terminal_order) + 1
  local next_terminal_name = self.terminal_order[next_index]

  -- Hide current terminal and show the next one
  local current_term_state = self.all_terminals[current_terminal_name]
  if vim.api.nvim_win_is_valid(current_term_state.win) then
    vim.api.nvim_win_hide(current_term_state.win)
    vim.api.nvim_win_hide(current_term_state.footer_win)
  end

  self:toggle_float_terminal(next_terminal_name)
end

---@param float_terminal_state Float_Term_State
function TerminalMultiplexer:create_float_window(float_terminal_state, terminal_name, do_not_open_win)
  local width = math.floor(vim.o.columns)
  local height = math.floor(vim.o.lines)
  local row = math.floor((vim.o.columns - width))
  local col = math.floor((vim.o.lines - height))

  if float_terminal_state.buf == -1 then
    float_terminal_state.buf = vim.api.nvim_create_buf(false, true)
  end
  float_terminal_state.footer_buf = vim.api.nvim_create_buf(false, true)

  local padding = string.rep(' ', width - #terminal_name - 1)
  local footer_text = padding .. terminal_name
  vim.api.nvim_buf_set_lines(float_terminal_state.footer_buf, 0, -1, false, { footer_text })
  vim.api.nvim_buf_add_highlight(float_terminal_state.footer_buf, -1, 'Title', 0, 0, -1)
  vim.api.nvim_buf_add_highlight(float_terminal_state.footer_buf, -1, 'TerminalNameUnderline', 0, #padding, -1)

  if not do_not_open_win then
    float_terminal_state.win = vim.api.nvim_open_win(float_terminal_state.buf, true, {
      relative = 'editor',
      width = width,
      height = height - 3,
      row = row,
      col = col,
      style = 'minimal',
      border = 'none',
    })

    vim.api.nvim_win_call(float_terminal_state.win, function() vim.cmd 'normal! G' end)
    float_terminal_state.footer_win = vim.api.nvim_open_win(float_terminal_state.footer_buf, false, {
      relative = 'win',
      width = width,
      height = 1,
      row = height - 3,
      col = 0,
      style = 'minimal',
      border = 'none',
    })
  end

  local map_opts = { noremap = true, silent = true, buffer = float_terminal_state.buf }
  local next_term = function() self:navigate_terminal(1) end
  local prev_term = function() self:navigate_terminal(-1) end

  vim.keymap.set('n', '>', next_term, map_opts)
  vim.keymap.set('n', '<', prev_term, map_opts)

  local close_term = function()
    if vim.api.nvim_win_is_valid(float_terminal_state.footer_win) then
      vim.api.nvim_win_hide(float_terminal_state.footer_win)
    end
    if vim.api.nvim_win_is_valid(float_terminal_state.win) then
      vim.api.nvim_win_hide(float_terminal_state.win)
    end
  end
  vim.keymap.set('n', 'q', close_term, map_opts)
end

--- === Toggle terminal ===

---@param terminal_name string
---@return Float_Term_State | nil
function TerminalMultiplexer:toggle_float_terminal(terminal_name, do_not_open_win)
  if not terminal_name then
    return nil
  end

  local current_float_term_state = self.all_terminals[terminal_name]
  if not current_float_term_state then
    current_float_term_state = {
      buf = -1,
      win = -1,
      chan = 0,
      footer_buf = -1,
      footer_win = -1,
    }
    self.all_terminals[terminal_name] = current_float_term_state
  end

  if not vim.tbl_contains(self.terminal_order, terminal_name) then
    table.insert(self.terminal_order, terminal_name)
  end

  local is_visible = vim.api.nvim_win_is_valid(current_float_term_state.win)

  if is_visible then
    vim.api.nvim_win_hide(current_float_term_state.win)
    vim.api.nvim_win_hide(current_float_term_state.footer_win)
    return self.all_terminals[terminal_name]
  end

  self:create_float_window(current_float_term_state, terminal_name, do_not_open_win)
  if vim.bo[current_float_term_state.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end
    current_float_term_state.chan = vim.bo.channel
  end

  return self.all_terminals[terminal_name]
end

function TerminalMultiplexer:delete_terminal(terminal_name)
  local float_terminal = self.all_terminals[terminal_name]
  if not float_terminal then
    return
  end

  vim.api.nvim_buf_delete(float_terminal.buf, { force = true })
  vim.api.nvim_buf_delete(float_terminal.footer_buf, { force = true })
  self.all_terminals[terminal_name] = nil

  for i, name in ipairs(self.terminal_order) do
    if name == terminal_name then
      table.remove(self.terminal_order, i)
      break
    end
  end
end

function TerminalMultiplexer:select_delete_terminal()
  local opts = {
    prompt = 'Select terminal:',
    format_item = function(item) return item end,
  }

  local all_terminal_names = {}
  for terminal_name, _ in pairs(self.all_terminals) do
    local term_state = self.all_terminals[terminal_name]
    if term_state then
      table.insert(all_terminal_names, terminal_name)
    end
  end

  local handle_choice = function(terminal_name)
    local float_terminal = self.all_terminals[terminal_name]
    vim.api.nvim_buf_delete(float_terminal.buf, { force = true })
    self.all_terminals[terminal_name] = nil
    for i, name in ipairs(self.terminal_order) do
      if name == terminal_name then
        table.remove(self.terminal_order, i)
        break
      end
    end
  end

  vim.ui.select(all_terminal_names, opts, function(choice) handle_choice(choice) end)
end

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

return TerminalMultiplexer
