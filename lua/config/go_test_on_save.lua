require 'config.util_find_test'
local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local job_id = -1
local ignored_actions = {
  pause = true,
  cont = true,
  start = true,
  skip = true,
}
local win_state = {
  floating = {
    buf = -1,
    win = -1,
  },
}

local make_key = function(entry)
  assert(entry.Package, 'Must have package name' .. vim.inspect(entry))
  if not entry.Test then
    return entry.Package
  end
  assert(entry.Test, 'Must have test name' .. vim.inspect(entry))
  return string.format('%s/%s', entry.Package, entry.Test)
end

local add_golang_test = function(bufnr, state, entry)
  local testLine = Find_test_line_by_name(bufnr, entry.Test)
  if not testLine then
    testLine = 0
  end
  state.tests[make_key(entry)] = {
    name = entry.Test,
    line = testLine - 1,
    output = {},
  }
end

local add_golang_output = function(state, entry)
  assert(state.tests, vim.inspect(state))
  table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
end

local mark_outcome = function(state, entry)
  local test = state.tests[make_key(entry)]
  if not test then
    return
  end
  test.success = entry.Action == 'pass'
end

local function get_enclosing_fn_info()
  local node = ts_utils.get_node_at_cursor()
  while node do
    if node:type() ~= 'function_declaration' then
      node = node:parent() -- Traverse up the node tree to find a function node
      goto continue
    end

    local func_name_node = node:child(1)
    if func_name_node then
      local func_name = get_node_text(func_name_node, 0)
      local startLine, _, _ = node:start()
      return startLine + 1, func_name -- +1 to convert 0-based to 1-based lua indexing system
    end
    ::continue::
  end

  return nil
end

local go_test_one_output = function(state)
  if vim.api.nvim_win_is_valid(win_state.floating.win) then
    vim.api.nvim_win_hide(win_state.floating.win)
    return
  end

  local _, testName = get_enclosing_fn_info()
  for _, test in pairs(state.tests) do
    if test.name == testName then
      win_state.floating.buf, win_state.floating.win = Create_floating_window(win_state.floating.buf)
      vim.api.nvim_buf_set_lines(win_state.floating.buf, 0, -1, false, test.output)
    end
  end
end

local go_test_all_output = function(state)
  if vim.api.nvim_win_is_valid(win_state.floating.win) then
    vim.api.nvim_win_hide(win_state.floating.win)
    return
  end

  local content = {}
  for _, decodedLine in ipairs(state.all_output) do
    local output = decodedLine.Output
    if output then
      local trimmed_str = string.gsub(output, '\n', '')
      table.insert(content, trimmed_str)
    end
  end
  win_state.floating.buf, win_state.floating.win = Create_floating_window(win_state.floating.buf)
  vim.api.nvim_buf_set_lines(win_state.floating.buf, 0, -1, false, content)
end

local create_tests_user_command = function(bufnr, group, ns, state)
  vim.api.nvim_create_user_command('GoTestAllOutput', function()
    go_test_all_output(state)
  end, {})
  vim.api.nvim_create_user_command('GoTestOutput', function()
    go_test_one_output(state)
  end, {})

  vim.keymap.set('n', '<localleader>ta', ':GoTestAllOutput<CR>', { desc = 'Go [T]est [A]ll Output' })
  vim.keymap.set('n', '<localleader>to', ':GoTestOutput<CR>', { desc = 'Go [T]est [O]utput' })

  vim.api.nvim_buf_create_user_command(bufnr, 'StopGoTestOnSave', function()
    vim.api.nvim_del_augroup_by_id(group)
    vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), ns, 0, -1)
    vim.diagnostic.reset()
  end, {})
end

local on_exit_fn = function(state, bufnr, ns)
  job_id = -1
  make_notify 'Test finished'
  local failed = {}
  for _, test in pairs(state.tests) do
    if not test.line or test.success then
      goto continue
    end

    table.insert(failed, {
      bufnr = bufnr,
      lnum = test.line,
      col = 0,
      severity = vim.diagnostic.severity.ERROR,
      source = 'go-test',
      message = 'Test Failed',
      user_data = {},
    })

    ::continue::
  end

  vim.diagnostic.set(ns, bufnr, failed, {})
end

local function clean_up_prev_job()
  if job_id ~= -1 then
    make_notify(string.format('Stopping job: %d', job_id))
    vim.fn.jobstop(job_id)
    vim.diagnostic.reset()
  end
end

local attach_to_buffer = function(bufnr, command, group, ns)
  local state = {
    bufnr = bufnr,
    tests = {},
    all_output = {},
  }
  create_tests_user_command(bufnr, group, ns, state)

  local extmark_ids = {}
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.go',
    callback = function()
      clean_up_prev_job()

      job_id = vim.fn.jobstart(command, {
        stdout_buffered = true,
        on_stdout = function(_, data)
          if not data then
            return
          end

          for _, line in ipairs(data) do
            if line == '' then
              goto continue
            end
            local decoded = vim.json.decode(line)
            assert(decoded, 'Failed to decode: ' .. line)
            table.insert(state.all_output, decoded)

            if ignored_actions[decoded.Action] then
              goto continue
            end

            if decoded.Action == 'run' then
              add_golang_test(bufnr, state, decoded)
              goto continue
            end

            if decoded.Action == 'output' then
              if decoded.Test then
                add_golang_output(state, decoded)
              end
              goto continue
            end

            local test = state.tests[make_key(decoded)]
            if not test then
              goto continue
            end

            if decoded.Action == 'pass' then
              mark_outcome(state, decoded)

              local test_extmark_id = extmark_ids[test.name]
              if test_extmark_id then
                vim.api.nvim_buf_del_extmark(bufnr, ns, test_extmark_id)
              end

              local current_time = os.date '%H:%M:%S'
              extmark_ids[test.name] = vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, -1, {
                virt_text = {
                  { string.format('%s %s', '✅', current_time) },
                },
              })
            end

            if decoded.Action == 'fail' then
              mark_outcome(state, decoded)
              local test_extmark_id = extmark_ids[test.name]
              if test_extmark_id then
                vim.api.nvim_buf_del_extmark(bufnr, ns, test_extmark_id)
              end
            end

            ::continue::
          end
        end,

        on_exit = function()
          on_exit_fn(state, bufnr, ns)
        end,
      })
    end,
  })
end

vim.api.nvim_create_user_command('GoTestAllOnSave', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  local concatTestName = ''
  for testName, _ in pairs(testsInCurrBuf) do
    concatTestName = concatTestName .. testName .. '|'
  end
  concatTestName = concatTestName:sub(1, -2) -- remove the last |
  local command = { 'go', 'test', './...', '-json', '-v', '-run', string.format('%s', concatTestName) }
  local group_all_tests = vim.api.nvim_create_augroup('all_tests_group', { clear = true })
  local ns_all_tests = vim.api.nvim_create_namespace 'live_tests_all'
  attach_to_buffer(bufnr, command, group_all_tests, ns_all_tests)
end, {})

local function get_enclosing_test()
  local _, testName = get_enclosing_fn_info()
  if not testName then
    print 'Not in a function'
    return nil
  end
  if not string.match(testName, 'Test_') then
    print(string.format('Not in a test function: %s', testName))
    return nil
  end
  return testName
end

local attach_single_test = function()
  local test_name = get_enclosing_test()
  make_notify(string.format('Attaching test: %s', test_name))
  local command = { 'go', 'test', './...', '-json', '-v', '-run', test_name }
  local group_one = vim.api.nvim_create_augroup('one_test_group', { clear = true })
  local ns_one = vim.api.nvim_create_namespace 'live_one_test'
  attach_to_buffer(vim.api.nvim_get_current_buf(), command, group_one, ns_one)
end

vim.api.nvim_create_user_command('GoTestOnSave', function()
  attach_single_test()
end, {})

vim.keymap.set('n', '<localleader>gt', ':GoTestOnSave<CR>', { desc = '[G]o [T]est On [S]ave' })
vim.keymap.set('n', '<localleader>sgt', ':StopGoTestOnSave<CR>', { desc = '[S]top [G]o [T]est On Save' })

vim.api.nvim_create_user_command('DriveTestOnSave', function()
  vim.env.UKS = 'others'
  vim.env.MODE = 'dev'
  attach_single_test()
end, {})

return {}
