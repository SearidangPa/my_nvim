require 'config.util_start_job'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local nui_input = require 'nui.input'
local event = require('nui.utils.autocmd').event

-- local width = math.floor(vim.o.columns * 0.9)
local height = math.floor(vim.o.lines * 0.25)
local row = math.floor((vim.o.lines - height) / 2)
local col = math.floor((vim.o.columns / 6))

local default_no_more_input = {
  '',
  '====================',
  'Done with what I set out to do',
}

local item_options = {
  'Save progress',
  'Checkpoint',
  'Half progress',
  'Refinement',
}

local choice_options = vim.list_extend(item_options, default_no_more_input)
local commit_msg = ''

local popup_option = {
  position = { row = row, col = col },
  size = { width = 120 },
  border = {
    style = 'rounded',
    text = {
      top = '[My Lovely Commit Message]',
      top_align = 'center',
    },
  },
  win_options = { winhighlight = 'Normal:Normal,FloatBorder:Normal' },
}

local function perform_commit(on_success_cb)
  ---@diagnostic disable-next-line: undefined-field
  local cmd = 'git commit -m "' .. commit_msg .. '"'
  Start_job {
    cmd = cmd,
    on_success_cb = on_success_cb,
    silent = true,
  }
end

local function git_add_all(on_success_cb)
  Start_job {
    cmd = 'git add .',
    on_success_cb = on_success_cb,
    silent = true,
  }
end

local function git_push()
  local commit_format_notification = [[Push successfully
Commit: %s]]

  Start_job {
    cmd = 'git push',
    on_success_cb = function()
      make_notify(string.format(commit_format_notification, commit_msg))
    end,
    silent = true,
  }
end

local function contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

local function handle_choice(choice, on_success_cb)
  if not choice then
    make_notify 'Commit aborted: no message selected.'
    return
  end

  commit_msg = choice

  if contains(default_no_more_input, choice) then
    perform_commit(on_success_cb)
    return
  end

  local nui_input_options = {
    prompt = '> ',
    default_value = string.format('%s: ', commit_msg),
    on_submit = function(value)
      commit_msg = value
      perform_commit(on_success_cb)
    end,
  }

  local input = nui_input(popup_option, nui_input_options)
  input:mount()

  input:on(event.BufLeave, function()
    input:unmount()
  end)
end

local function git_commit_with_message_prompt(on_success_cb)
  local opts = {
    prompt = 'Select suggested commit message:',
    format_item = function(item)
      return item
    end,
  }

  vim.ui.select(choice_options, opts, function(choice)
    handle_choice(choice, on_success_cb)
  end)
end

local function push_add_all()
  git_add_all(function()
    git_commit_with_message_prompt(function()
      git_push()
    end)
  end)
end

vim.keymap.set('n', '<leader>pa', push_add_all, {
  noremap = true,
  silent = true,
  desc = '[P]ush [A]dd all',
})

return {}
