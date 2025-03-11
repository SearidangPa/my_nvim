local M = {}
local make_notify = require('mini.notify').make_notify {}
M.float_win = -1
M.float_buf = -1
M.output_lines = {}

-- Function to execute shell commands and return the output
local function execute_command(command)
  local handle = io.popen(command)
  assert(handle, 'Failed to execute command: ' .. command)
  local result = handle:read '*a'
  handle:close()
  return result
end

-- Function to append lines to our output buffer
local function append_output(text, highlight)
  highlight = highlight or 'Normal'
  table.insert(M.output_lines, { text = text, hl = highlight })

  -- If the buffer is valid, update it
  if M.float_buf ~= -1 and vim.api.nvim_buf_is_valid(M.float_buf) then
    local lines = {}
    for _, line in ipairs(M.output_lines) do
      table.insert(lines, line.text)
    end

    vim.api.nvim_buf_set_lines(M.float_buf, 0, -1, false, lines)

    -- Apply highlights
    for i, line in ipairs(M.output_lines) do
      if line.hl ~= 'Normal' then
        vim.api.nvim_buf_add_highlight(M.float_buf, -1, line.hl, i - 1, 0, -1)
      end
    end
  end
end

-- Function to create or show the floating window
function M.show_actions_window()
  -- If window exists and is valid, focus it and return
  if M.float_win ~= -1 and vim.api.nvim_win_is_valid(M.float_win) then
    vim.api.nvim_set_current_win(M.float_win)
    return
  end

  -- Create a new buffer if needed
  if M.float_buf == -1 or not vim.api.nvim_buf_is_valid(M.float_buf) then
    M.float_buf = vim.api.nvim_create_buf(false, true)

    -- Set buffer options
    vim.api.nvim_set_option_value('wrap', true, { buf = M.float_buf })
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = M.float_buf })

    -- Set keymaps for the buffer
    vim.api.nvim_buf_set_keymap(M.float_buf, 'n', 'q', ':lua require("github-actions").close_actions_window()<CR>', { noremap = true, silent = true })
  end

  -- Calculate window dimensions
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Create the floating window
  M.float_win = vim.api.nvim_open_win(M.float_buf, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = 'GitHub Actions Status',
    title_pos = 'center',
  })

  -- Set window options
  vim.api.nvim_set_option_value('cursorline', true, { win = M.float_win })
  vim.api.nvim_set_option_value('wrap', true, { win = M.float_win })

  -- Update the content
  local lines = {}
  for _, line in ipairs(M.output_lines) do
    table.insert(lines, line.text)
  end

  vim.api.nvim_buf_set_lines(M.float_buf, 0, -1, false, lines)

  -- Apply highlights
  for i, line in ipairs(M.output_lines) do
    if line.hl ~= 'Normal' then
      vim.api.nvim_buf_add_highlight(M.float_buf, -1, line.hl, i - 1, 0, -1)
    end
  end
end

function M.close_actions_window()
  if M.float_win ~= -1 and vim.api.nvim_win_is_valid(M.float_win) then
    vim.api.nvim_win_close(M.float_win, true)
    M.float_win = -1
  end
end

-- Check GitHub Actions status for the latest commit
function M.check_gh_actions_retry_failed()
  -- Clear previous output
  M.output_lines = {}

  local current_branch = execute_command('git branch --show-current'):gsub('%s+$', '')
  local latest_commit = execute_command('git rev-parse HEAD'):gsub('%s+$', '')

  append_output('Checking GitHub Actions for branch: ' .. current_branch)
  append_output('Latest commit: ' .. latest_commit)
  append_output ''

  local workflow_runs = execute_command('gh run list --commit ' .. latest_commit .. ' --json databaseId,status,conclusion,name,headSha')

  if workflow_runs == '' then
    append_output('No workflow runs found for latest commit', 'WarningMsg')
    return 1
  end

  -- Parse JSON with Lua
  local json_parsed, json_result = pcall(vim.fn.json_decode, workflow_runs)
  if not json_parsed then
    append_output('Error parsing GitHub Action results', 'ErrorMsg')
    return 1
  end

  -- Display workflow status
  for _, run in ipairs(json_result) do
    local conclusion = run.conclusion or 'pending'
    local status_color = 'Normal'

    if conclusion ~= 'success' and run.status ~= 'in_progress' and run.status ~= 'queued' then
      status_color = 'ErrorMsg'
    elseif run.status == 'in_progress' or run.status == 'queued' then
      status_color = 'WarningMsg'
    else
      status_color = 'String' -- Green for success
    end

    append_output(run.name .. ': ' .. run.status .. ' - ' .. conclusion, status_color)
  end

  append_output ''

  -- Check for failed runs
  local failed_runs = {}
  for _, run in ipairs(json_result) do
    if run.conclusion ~= 'success' and run.conclusion ~= nil then
      table.insert(failed_runs, { id = run.databaseId, name = run.name })
    end
  end

  -- Check for pending runs
  local pending_runs = {}
  for _, run in ipairs(json_result) do
    if run.status == 'in_progress' or run.status == 'queued' then
      table.insert(pending_runs, { id = run.databaseId, name = run.name })
    end
  end

  -- Handle failed runs
  if #failed_runs > 0 then
    append_output('Failed workflow runs detected. Rerunning failed jobs...', 'WarningMsg')

    for _, run in ipairs(failed_runs) do
      append_output("Rerunning failed jobs for workflow: '" .. run.name .. "' (ID: " .. run.id .. ')')
      execute_command('gh run rerun --failed ' .. run.id)
    end

    append_output('Rerun initiated for all failed jobs.', 'String')
    return 3
  end

  -- Handle pending runs
  if #pending_runs > 0 then
    append_output('Some workflows are still running. Please wait for them to complete.', 'WarningMsg')
    return 2
  end

  -- All successful
  append_output('SUCCESS: All GitHub Actions workflow runs have completed successfully!', 'String')
  return 0
end

-- Function to retry until success
function M.retry_until_success(interval_minutes)
  interval_minutes = interval_minutes or 5 -- Default to 5 minutes if no value provided
  local interval_seconds = interval_minutes * 60

  -- Clear previous output
  M.output_lines = {}
  append_output('Starting retry loop with ' .. interval_minutes .. ' minute interval...')
  append_output ''

  local status = 0
  local attempt = 1

  local retry_fn
  retry_fn = function()
    append_output('Attempt #' .. attempt .. ':', 'Title')

    status = M.check_gh_actions_retry_failed()

    -- Always show the window after each check
    vim.schedule(function() M.show_actions_window() end)

    if status == 0 then
      -- Success
      append_output('🎉 All GitHub Actions have succeeded!', 'String')
      return
    elseif status == 3 then
      -- Failed and rerun
      append_output('⏳ Some jobs failed and were rerun. Waiting ' .. interval_minutes .. ' minutes before checking again...', 'WarningMsg')
      vim.defer_fn(function()
        attempt = attempt + 1
        retry_fn()
      end, interval_seconds * 1000)
    elseif status == 2 then
      -- Pending
      append_output('⏳ Some jobs are still pending. Waiting ' .. interval_minutes .. ' minutes before checking again...', 'WarningMsg')
      vim.defer_fn(function()
        attempt = attempt + 1
        retry_fn()
      end, interval_seconds * 1000)
    else
      -- Error
      append_output('❌ Error checking GitHub Actions. Please check manually.', 'ErrorMsg')
    end
  end

  -- Start the retry loop
  retry_fn()

  -- Show window after starting
  vim.schedule(function() M.show_actions_window() end)
end

vim.api.nvim_create_user_command('GhActionsCheckRetry', function() M.check_gh_actions_retry_failed() end, {})
vim.api.nvim_create_user_command('GhActionsRetryTillSuccess', function(opts)
  local interval = tonumber(opts.args) or 7
  M.retry_until_success(interval)
end, { nargs = '?' })

vim.api.nvim_create_user_command('GhActionsStatus', function() M.show_actions_window() end, {})
return M
