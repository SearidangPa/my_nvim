local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local term_channel_id = 0

local state = {
  floating = {
    buf = -1,
    win = -1,
  },
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

    term_channel_id = vim.bo.channel
    print('term_channel_id here' .. term_channel_id)
  end
end

local function map_opt(desc)
  return { noremap = true, silent = false, desc = desc }
end

vim.keymap.set({ 't', 'n' }, '<localleader>ti', function()
  toggle_floating_terminal()
  vim.api.nvim_feedkeys('i', 'n', true)
end, map_opt '[T]erminal [I]nsert')

vim.keymap.set({ 't', 'n' }, '<localleader>tt', function()
  toggle_floating_terminal()
end, map_opt '[T]erminal [T]oggle')

local choice_options = {
  'gst',
  'rds',
  '<Ctrl-C>',
  '========= windows only ===========',
  'un;Remove-Item -Path ~\\Documents\\Prevel_Sync_Root\\* -Recurse -Force',
  're;st',
}

local function handle_choice(choice, channel_id, is_small_terminal)
  if not choice then
    make_notify 'No choice selected'
    return
  end

  if not is_small_terminal then
    vim.api.nvim_feedkeys('i', 'n', true)
    if choice == '<Ctrl-C>' then
      vim.fn.chansend(channel_id, '\x03')
    else
      vim.fn.chansend(channel_id, string.format('%s\n', choice))
    end

    if not vim.api.nvim_win_is_valid(state.floating.win) then
      toggle_floating_terminal()
    end
    vim.api.nvim_feedkeys('<Esc><Esc>', 'i', true)

    -- local term_view_timer = 3000 -- milliseconds
    -- vim.defer_fn(function()
    --   toggle_floating_terminal()
    -- end, term_view_timer)
  end
end

local function send_command_to_terminal(channel_id, is_small_terminal)
  local opts = {
    prompt = 'Select command to send to terminal',
    format_item = function(item)
      return item
    end,
  }

  -- if not is_small_terminal then
  --   if not vim.api.nvim_win_is_valid(state.floating.win) then
  --     state.floating.buf, state.floating.win = Create_floating_window(state.floating.buf)
  --     if vim.fn.has 'win32' == 1 then
  --       vim.cmd.term 'powershell.exe'
  --     else
  --       vim.cmd.term()
  --     end
  --     channel_id = vim.bo.channel
  --     vim.api.nvim_win_hide(state.floating.win)
  --   end
  -- end

  vim.ui.select(choice_options, opts, function(choice)
    handle_choice(choice, channel_id, is_small_terminal)
  end)
end

vim.keymap.set('n', '<localleader>tc', function()
  print('term_channel_id', term_channel_id)
  send_command_to_terminal(term_channel_id, false)
end, { desc = '[T]erminal [C]ommand' })

local small_terminal_chan = 0
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

vim.keymap.set('n', '<localleader>ts', small_terminal, { desc = '[S]mall [T]erminal' })

vim.keymap.set('n', '<localleader>tx', function()
  send_command_to_terminal(small_terminal_chan, true)
end, { desc = '[T]erminal e[x]ecute' })

return {}
