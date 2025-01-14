local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local floating_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
}

local small_term_state = {
  buf = -1,
  win = -1,
  chan = 0,
}

local function map_opt(desc)
  return { noremap = true, silent = false, desc = desc }
end

local choice_options = {
  'gst',
  'rds',
  '<Ctrl-C>',
  '========= windows only ===========',
  'un;Remove-Item -Path ~\\Documents\\Prevel_Sync_Root\\* -Recurse -Force',
  're;st',
}

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

local function focus_above_small_terminal()
  if not vim.api.nvim_win_is_valid(small_term_state.win) then
    return
  end

  local small_term_pos = vim.api.nvim_win_get_position(small_term_state.win)
  local windows = vim.api.nvim_tabpage_list_wins(0)

  local target_win = nil
  for _, win in ipairs(windows) do
    if win ~= small_term_state.win then
      local pos = vim.api.nvim_win_get_position(win)
      if pos[1] < small_term_pos[1] then
        target_win = win
      end
    end
  end

  if target_win then
    vim.api.nvim_set_current_win(target_win)
  end
end

function Create_floating_window(buf_intput)
  buf_intput = buf_intput or -1
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local row = math.floor((vim.o.columns - width))
  local col = math.floor((vim.o.lines - height))

  local buf = nil
  if buf_intput == -1 then
    buf = vim.api.nvim_create_buf(false, true)
  else
    buf = buf_intput
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

local toggle_floating_terminal = function()
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
end

local function small_terminal()
  vim.cmd.vnew()
  if vim.fn.has 'win32' == 1 then
    vim.cmd.term 'powershell.exe'
  else
    vim.cmd.term()
  end
  vim.cmd.wincmd 'J'

  local small_term_height = 12
  vim.api.nvim_win_set_height(0, small_term_height)
  small_term_state.buf = vim.api.nvim_get_current_buf()
  small_term_state.win = vim.api.nvim_get_current_win()
  small_term_state.chan = vim.bo.channel
end

local function toggle_small_terminal()
  if vim.api.nvim_win_is_valid(small_term_state.win) then
    vim.api.nvim_win_hide(small_term_state.win)
    return
  end

  if not vim.api.nvim_buf_is_valid(small_term_state.buf) then
    small_terminal()
    return
  end

  small_term_state.win = vim.api.nvim_open_win(small_term_state.buf, true, {
    relative = 'editor',
    width = vim.o.columns,
    height = 12,
    row = vim.o.lines - 12,
    col = 0,
    style = 'minimal',
  })
  vim.cmd.wincmd 'J'

  small_term_state.chan = vim.bo.channel
end

local function handle_choice(choice, is_float)
  local channel_id, buf, win
  if is_float then
    if not vim.api.nvim_win_is_valid(floating_term_state.win) then
      toggle_floating_terminal()
    end
    channel_id = floating_term_state.chan
    buf = floating_term_state.buf
    win = floating_term_state.win
  else
    if not vim.api.nvim_win_is_valid(small_term_state.win) then
      toggle_small_terminal()
    end
    channel_id = small_term_state.chan
    buf = small_term_state.buf
    win = small_term_state.win
  end

  if choice == '<Ctrl-C>' then
    vim.fn.chansend(channel_id, '\x03')
  else
    vim.fn.chansend(channel_id, string.format('%s\n', choice))
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_win_set_cursor(win, { line_count, 0 })

  if not is_float then
    focus_above_small_terminal()
  end
end

local function send_command_toggle_term(is_float)
  local opts = {
    prompt = 'Select command to send to terminal',
    format_item = function(item)
      return item
    end,
  }

  vim.ui.select(choice_options, opts, function(choice)
    if not choice then
      make_notify 'No choice selected'
      return
    end
    handle_choice(choice, is_float)
  end)
end

vim.keymap.set('n', '<localleader>tc', function()
  send_command_toggle_term(true)
end, { desc = '[T]erminal [C]ommand' })

vim.keymap.set('n', '<localleader>ts', function()
  send_command_toggle_term(false)
end, { desc = '[S]mall [T]erminal' })

vim.keymap.set({ 't', 'n' }, '<localleader>tt', toggle_floating_terminal, map_opt '[T]erminal [T]oggle')
vim.keymap.set('n', '<localleader><localleader>', function()
  toggle_small_terminal()
end, { desc = 'Toggle small terminal' })
return {}
