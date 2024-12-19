local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local commit_msg = ''

local function git_add(on_success_cb)
  vim.fn.jobstart('git add .', {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        on_success_cb()
      else
        make_notify 'Git add all failed.'
      end
    end,
  })
end

local git_push_format_notification = [[
Git push successful!
commit: %s
]]

local function git_push()
  vim.fn.jobstart('git push', {
    on_exit = function(_, exit_code)
      if exit_code ~= 0 then
        make_notify 'Git push failed'
        return
      end
      make_notify(string.format(git_push_format_notification, commit_msg))
    end,
  })
end

local function perform_commit(on_success_cb)
  local escaped_msg = commit_msg:gsub('"', '\\"') -- Escape double quotes in commit_msg to prevent shell issues
  local cmd = 'git commit -m "' .. escaped_msg .. '"'

  vim.fn.jobstart(cmd, {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        make_notify 'Git commit successful.'
        if on_success_cb then
          on_success_cb()
        end
      else
        make_notify 'Git commit failed.'
      end
    end,
  })
end

local function handle_choice(choice, on_success)
  if not choice then
    make_notify 'Commit aborted: no message selected.'
    return
  end

  if choice == 'Custom input' then
    vim.ui.input({ prompt = 'Enter Commit Message: ' }, function(input_msg)
      if not input_msg or vim.trim(input_msg) == '' then
        make_notify 'Commit aborted: no message provided.'
        return
      end
      commit_msg = input_msg
      perform_commit(on_success)
    end)
  else
    perform_commit(on_success)
  end
end

local function git_commit_with_message_prompt(on_success_cb)
  local options = {
    'Improve log',
    'Save progress',
    'Done',
    'Custom input',
  }

  vim.ui.select(options, {
    prompt = 'Select Commit Message:',
    format_item = function(item)
      commit_msg = item
      return item
    end,
  }, function(choice)
    handle_choice(choice, on_success_cb)
  end)
end

local function push_all()
  git_add(function()
    git_commit_with_message_prompt(function()
      git_push(commit_msg)
    end)
  end)
end

vim.keymap.set('n', '<leader>pa', push_all, {
  noremap = true,
  silent = true,
  desc = 'push all',
})

return {}
