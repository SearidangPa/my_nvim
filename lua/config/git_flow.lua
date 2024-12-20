require 'config.util_start_job'
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local nui_input = require 'nui.input'
local event = require('nui.utils.autocmd').event

local width = math.floor(vim.o.columns * 0.9)
local height = math.floor(vim.o.lines * 0.25)
local row = math.floor((vim.o.columns - width))
local col = math.floor((vim.o.lines - height))

local item_options = {
  'Save progress',
  'Done with what I set out to do',
  'Custom input',
}

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

local some_nice_quotes = {
  '“What is hell? I maintain that it is the suffering of being unable to love.”-- Fyodor Dostoevsky',
  '“Beauty will save the world”-- Fyodor Dostoevsky',
  '“I can see the sun, but even if I cannot see the sun, I know that it exists. And to know that the sun is there - that is living.”-- Fyodor Dostoevsky',
}

local git_push_format_notification = [[
Git push successful!
commit: %s
]]

local function perform_commit(on_success_cb, commit_msg)
  ---@diagnostic disable-next-line: undefined-field
  local escaped_msg = commit_msg:gsub('"', '\\"') -- Escape double quotes in commit_msg to prevent shell issues
  local cmd = 'git commit -m "' .. escaped_msg .. '"'
  Start_job {
    cmd = cmd,
    on_success_cb = on_success_cb,
    silent = true,
  }
end

local function git_add(on_success_cb)
  Start_job {
    cmd = 'git add .',
    on_success_cb = on_success_cb,
    silent = true,
  }
end

local function git_push()
  Start_job {
    cmd = 'git push',
    on_success_cb = function()
      make_notify(string.format(git_push_format_notification))
    end,
    silent = false,
  }
end

local function handle_choice(choice, on_success_cb)
  if not choice then
    make_notify 'Commit aborted: no message selected.'
    return
  end

  if choice ~= 'Custom input' then
    perform_commit(on_success_cb, choice)
    return
  end

  local random_index = math.random(1, #some_nice_quotes)
  local selected_quote = some_nice_quotes[random_index]

  local commit_msg = ''
  local nui_input_options = {
    prompt = '> ',
    default_value = selected_quote,
    on_submit = function(value)
      commit_msg = value
    end,
  }

  local input = nui_input(popup_option, nui_input_options)
  input:mount()

  local on_leave = function()
    input:unmount()
    if commit_msg == '' then
      make_notify 'Commit aborted: no message provided.'
      return
    end

    perform_commit(on_success_cb, commit_msg)
  end

  input:on(event.BufLeave, on_leave)
end

local function git_commit_with_message_prompt(on_success_cb)
  local opts = {
    prompt = 'Select Commit Message:',
    format_item = function(item)
      return item
    end,
  }

  vim.ui.select(item_options, opts, function(choice)
    handle_choice(choice, on_success_cb)
  end)
end

local function push_all()
  git_add(function()
    git_commit_with_message_prompt(function()
      git_push()
    end)
  end)
end

vim.keymap.set('n', '<leader>pa', push_all, {
  noremap = true,
  silent = true,
  desc = '[P]ush [A]ll',
})

return {}
