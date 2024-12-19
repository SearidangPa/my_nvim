local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}
local commit_msg = ''

local function git_add(on_success)
  vim.fn.jobstart('git add .', {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        on_success()
      else
        make_notify 'Git add all failed.'
      end
    end,
  })
end

local function git_commit(on_success)
  commit_msg = vim.fn.input 'Commit message: '
  if commit_msg == '' then
    make_notify 'Commit aborted: no message provided.'
    return
  end

  vim.fn.jobstart('git commit -m "' .. commit_msg .. '"', {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        on_success()
      else
        make_notify 'Git commit failed'
      end
    end,
  })
end

local function git_push()
  vim.fn.jobstart('git push', {
    on_exit = function(_, exit_code)
      if exit_code == 0 then
        make_notify(string.format(
          [[Git push successful!
commit: %s
          ]],
          commit_msg
        ))
      else
        make_notify 'Git push failed'
      end
    end,
  })
end

local function fugitive_git_workflow()
  git_add(function()
    git_commit(function()
      git_push()
    end)
  end)
end

vim.keymap.set('n', '<leader>gcp', fugitive_git_workflow, {
  noremap = true,
  silent = true,
  desc = 'Git workflow: add, commit, push',
})

-- [[
-- Playing with the ui module
-- ]]

local function handle_custom_input(input_msg)
  if not input_msg or vim.trim(input_msg) == '' then
    make_notify 'Commit aborted: no message provided.'
    return
  end
  make_notify('Custom input: ' .. input_msg)
end

local function play_prompt_input()
  local options = {
    'Improve log',
    'Save progress',
    'Done',
    'Custom input',
  }

  vim.ui.select(options, {
    prompt = 'Select Commit Message:',
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if not choice then
      make_notify 'Commit aborted: no message selected.'
      return
    end

    if choice == 'Custom input' then
      vim.ui.input({
        prompt = 'Enter Commit Message: ',
      }, handle_custom_input)
    else
    end
  end)
end

vim.keymap.set('n', '<leader>p', play_prompt_input, {
  noremap = true,
  silent = true,
  desc = 'play prompt input',
})

return {}
