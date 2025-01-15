local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

Choice_options_unix = {
  'cs && MIX_ENV=dev USER_CREATES_PER_HOUR=9000000000000 iex --sname cs@localhost --cookie blih --erl "-kernel prevent_overlapping_partitions false +P 1000000" -S mix',
}

Choice_options_win = {
  'dr; rds',
  'un; Remove-Item -Path ~\\Documents\\Preveil_Sync_Root\\* -Recurse -Force -Confirm:$false; re;st',
  're;st',
}

vim.api.nvim_create_autocmd('TermOpen', {
  group = vim.api.nvim_create_augroup('custom-term-open', { clear = true }),
  callback = function()
    vim.opt.number = false
    vim.opt.relativenumber = false
  end,
})

function Send_command_toggle_term(opts)
  local ui_select_opts = {
    prompt = 'Select command to send to terminal',
    format_item = function(item)
      return item
    end,
  }
  local choice_options
  if vim.fn.has 'win32' == 1 then
    choice_options = Choice_options_win
  else
    choice_options = Choice_options_unix
  end

  vim.ui.select(choice_options, ui_select_opts, function(choice)
    if not choice then
      make_notify 'No choice selected'
      return
    end
    Handle_choice {
      choice = choice,
      is_float = opts.is_float,
      toggle_term_func = opts.toggle_term_func,
      term_state = opts.term_state,
    }
  end)
end

local function focus_above_small_terminal(small_term_state)
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

function Handle_choice(opts)
  local is_float = opts.is_float
  local choice = opts.choice
  local term_state = opts.term_state
  local toggle_term_func = opts.toggle_term_func

  local channel_id, buf
  local win = term_state.win
  if not vim.api.nvim_win_is_valid(win) then
    win = toggle_term_func()
  end

  channel_id = term_state.chan
  buf = term_state.buf

  if choice == '<Ctrl-C>' then
    vim.fn.chansend(channel_id, '\x03')
  else
    vim.fn.chansend(channel_id, string.format('%s\r\n', choice))
  end

  local line_count = vim.api.nvim_buf_line_count(buf)
  vim.api.nvim_win_set_cursor(win, { line_count, 0 })

  if not is_float then
    focus_above_small_terminal(term_state)
  end
end
