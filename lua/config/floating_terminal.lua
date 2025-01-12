local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local nui_input = require 'nui.input'
local event = require('nui.utils.autocmd').event

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
  '',
  'gst',

  '========= windows only ===========',
  'un;Remove-Item -Path ~\\Documents\\Prevel_Sync_Root\\* -Recurse -Force',
  're;st',
}

local function handle_choice(choice)
  if not choice then
    make_notify 'No choice selected'
    return
  end

  local nui_input_options = {
    prompt = '> ',
    default_value = choice,
    on_submit = function(value)
      vim.fn.chansend(term_channel_id, string.format('%s\n', value))
    end,
  }

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.25)
  local row = math.floor((vim.o.columns - width))
  local col = math.floor((vim.o.lines - height))

  local popup_option = {
    position = { row = row, col = col },
    size = { width = 120 },
    border = {
      style = 'rounded',
      text = {
        top = '[My lovely command to send to terminal]',
        top_align = 'center',
      },
    },
    win_options = { winhighlight = 'Normal:Normal,FloatBorder:Normal' },
  }

  local input = nui_input(popup_option, nui_input_options)
  input:mount()

  input:on(event.BufLeave, function()
    input:unmount()
  end)
end

local function send_command_to_terminal()
  local opts = {
    prompt = 'Select command to send to terminal',
    format_item = function(item)
      return item
    end,
  }

  vim.ui.select(choice_options, opts, function(choice)
    handle_choice(choice)
  end)
end

vim.keymap.set('n', '<localleader>tc', send_command_to_terminal, { desc = '[T]erminal [C]ommand' })

return {}
