require 'config.util_find_func'
local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text
local mini_notify = require 'mini.notify'
local make_notify = mini_notify.make_notify {}

local group, ns

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
    fail_at_line = 0,
  }
end

local add_golang_output = function(state, entry)
  assert(state.tests, vim.inspect(state))
  local trimmed_output = vim.trim(entry.Output)
  local file, line = string.match(trimmed_output, '([%w_]+%.go):(%d+):')
  table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
  if file and line then
    state.tests[make_key(entry)].fail_at_line = tonumber(line)
  end
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

local on_exit_fn = function(state, bufnr)
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

local attach_to_buffer = function(bufnr, command)
  local state = {
    bufnr = bufnr,
    tests = {},
    all_output = {},
  }
  local function output_go_test()
    go_test_one_output(state)
  end

  local function output_go_test_all()
    go_test_all_output(state)
  end

  vim.api.nvim_create_user_command('GoTestOutputAll', output_go_test_all, {})
  vim.api.nvim_create_user_command('GoOutputTest', output_go_test, {})

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
              if test.fail_at_line > 0 then
                local current_time = os.date '%H:%M:%S'
                extmark_ids[test.name] = vim.api.nvim_buf_set_extmark(bufnr, ns, test.fail_at_line - 1, -1, {
                  virt_text = {
                    { string.format(' \t%s %s', '❌', current_time) },
                  },
                })
              end
            end

            ::continue::
          end
        end,

        on_exit = function()
          on_exit_fn(state, bufnr)
        end,
      })
    end,
  })
end

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

local clear_previous_group_and_ns_if_exists = function()
  if group == nil or ns == nil then
    return
  end
  local ok, _ = pcall(vim.api.nvim_get_autocmds, { group = 'live_go_test_group' })
  if not ok then
    return
  end
  vim.api.nvim_del_augroup_by_name 'live_go_test_group'
  vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), ns, 0, -1)
  vim.diagnostic.reset()
end

local attach_single_test = function()
  local test_name = get_enclosing_test()
  make_notify(string.format('Attaching test: %s', test_name))
  local command = { 'go', 'test', './...', '-json', '-v', '-run', test_name }
  group = vim.api.nvim_create_augroup('live_go_test_group', { clear = true })
  ns = vim.api.nvim_create_namespace 'live_go_test_ns'
  attach_to_buffer(vim.api.nvim_get_current_buf(), command)
end

local attach_go_test_on_save = function()
  clear_previous_group_and_ns_if_exists()
  attach_single_test()
end

local attach_go_test_all = function()
  clear_previous_group_and_ns_if_exists()
  local bufnr = vim.api.nvim_get_current_buf()
  local testsInCurrBuf = Find_all_tests(bufnr)
  local concatTestName = ''
  for testName, _ in pairs(testsInCurrBuf) do
    concatTestName = concatTestName .. testName .. '|'
  end
  concatTestName = concatTestName:sub(1, -2) -- remove the last |
  local command = { 'go', 'test', './...', '-json', '-v', '-run', string.format('%s', concatTestName) }
  group = vim.api.nvim_create_augroup('live_go_test_group', { clear = true })
  ns = vim.api.nvim_create_namespace 'live_go_test_ns'
  attach_to_buffer(bufnr, command)
end

vim.api.nvim_create_user_command('GoTestOnSave', attach_go_test_on_save, {})
vim.api.nvim_create_user_command('GoTestOnSaveAll', attach_go_test_all, {})
vim.api.nvim_create_user_command('GoClearTestOnSave', clear_previous_group_and_ns_if_exists, {})

vim.keymap.set('n', '<leader>gt', attach_go_test_on_save, { desc = '[T]oggle [G]o Test on save' })
vim.keymap.set('n', '<leader>go', ':GoOutputTest<CR>', { desc = '[G]o [O]utput Test ' })
vim.keymap.set('n', '<leader>gc', clear_previous_group_and_ns_if_exists, { desc = '[G]o [C]lear test on save' })
vim.keymap.set('n', '<leader>ga', attach_go_test_all, { desc = '[G]o test [A]ll on save' })

vim.api.nvim_create_user_command('DriveTestOnSave', function()
  vim.env.UKS = 'others'
  vim.env.MODE = 'dev'
  attach_single_test()
end, {})

return {}
