local map = vim.keymap.set
local function map_opt(desc) return { noremap = true, silent = true, desc = desc } end

local function accept(opts)
  opts = opts or {}
  local no_indentation = opts.no_indentation or false
  local only_one_line = opts.only_one_line or false
  local accept_fn
  if only_one_line then
    accept_fn = vim.fn['copilot#AcceptLine']
  else
    accept_fn = vim.fn['copilot#Accept']
  end
  assert(accept_fn, 'copilot accept or accept line not found')
  local res = accept_fn()
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local next_line = cursor_pos[1]
  local next_line_content = vim.api.nvim_buf_get_lines(0, next_line, next_line + 1, false)
  local is_next_line_empty = next_line_content[1] and next_line_content[1]:match '^%s*$'
  if is_next_line_empty and not no_indentation then
    res = res .. '\n'
  end
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function add_doc_above_func()
  local util_find_func = require 'custom.util_find_func'
  local original_cursor_pos = vim.api.nvim_win_get_cursor(0)
  util_find_func.visual_function()
  vim.schedule(function()
    require('codecompanion').prompt 'docfn'
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true)
    vim.api.nvim_win_set_cursor(0, original_cursor_pos)
  end)
end

map({ 'v', 'n' }, '<localleader>ad', add_doc_above_func, map_opt 'Add doc above function')
map('i', '<M-s>', function() require('hopcopilot').hop_copilot() end, map_opt 'hop copilot')
map('i', '<M-y>', accept, map_opt 'Accept Copilot all')
map('i', '<D-s>', function() require('hopcopilot').hop_copilot() end, map_opt 'hop copilot')
map('i', '<D-y>', accept, map_opt 'Accept Copilot all')
map('i', '<C-l>', function() accept { no_indentation = true, only_one_line = true } end, map_opt 'Accept copilot one line')
map('v', '<localleader>av', function() require('codecompanion').prompt 'docfn' end, map_opt 'Add doc to visual select')
