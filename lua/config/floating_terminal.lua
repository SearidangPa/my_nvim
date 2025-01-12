local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local floating_term_chan = 0
local small_terminal_chan = 0

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
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
  if vim.api.nvim_win_is_valid(state.floating.win) then
    vim.api.nvim_win_hide(state.floating.win)
    return
  end

  state.floating.buf, state.floating.win = Create_floating_window(state.floating.buf)
  if vim.bo[state.floating.buf].buftype ~= 'terminal' then
    if vim.fn.has 'win32' == 1 then
      vim.cmd.term 'powershell.exe'
    else
      vim.cmd.term()
    end

    floating_term_chan = vim.bo.channel
  end
end

local function handle_choice(choice, is_float)
  local channel_id
  if is_float then
    if not vim.api.nvim_win_is_valid(state.floating.win) then
      toggle_floating_terminal()
    end
    channel_id = floating_term_chan
  else
    channel_id = small_terminal_chan
  end

  if choice == '<Ctrl-C>' then
    vim.fn.chansend(channel_id, '\x03')
  else
    vim.fn.chansend(channel_id, string.format('%s\n', choice))
  end

  if is_float then
    local line_count = vim.api.nvim_buf_line_count(state.floating.buf)
    vim.api.nvim_win_set_cursor(state.floating.win, { line_count, 0 })
  end
end

local function send_command_to_terminal(is_float)
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
  small_terminal_chan = vim.bo.channel
  return small_terminal_chan
end

vim.keymap.set('n', '<localleader>tc', function()
  send_command_to_terminal(true)
end, { desc = '[T]erminal [C]ommand' })

vim.keymap.set('n', '<localleader>tx', function()
  send_command_to_terminal(false)
end, { desc = '[T]erminal e[x]ecute' })

vim.keymap.set({ 't', 'n' }, '<localleader>tt', toggle_floating_terminal, map_opt '[T]erminal [T]oggle')
vim.keymap.set('n', '<localleader>ts', small_terminal, { desc = '[S]mall [T]erminal' })
return {}
