require 'config.util_find_func'
require 'config.util_go_test_on_save'

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

local go_test_one_output = function(state)
  if vim.api.nvim_win_is_valid(win_state.floating.win) then
    vim.api.nvim_win_hide(win_state.floating.win)
    return
  end

  local _, testName = Get_enclosing_fn_info()
  for _, test in pairs(state.tests) do
    if test.name == testName then
      win_state.floating.buf, win_state.floating.win = Create_floating_window(win_state.floating.buf)
      vim.api.nvim_buf_set_lines(win_state.floating.buf, 0, -1, false, test.output)
    end
  end
end

local on_exit_fn = function(state, bufnr)
  job_id = -1
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

  if #failed == 0 then
    make_notify 'Test failed'
  else
    make_notify 'Test passed'
  end

  vim.diagnostic.set(ns, bufnr, failed, {})
end

local attach_to_buffer = function(bufnr, command)
  local test_state = {
    bufnr = bufnr,
    tests = {},
    all_output = {},
  }
  local function output_one_go_test()
    go_test_one_output(test_state)
  end

  local function output_go_test_all()
    Go_test_all_output(test_state, win_state)
  end

  vim.api.nvim_create_user_command('OutputAllTest', output_go_test_all, {})
  vim.api.nvim_create_user_command('OutputOneTest', output_one_go_test, {})
  vim.keymap.set('n', '<leader>go', output_one_go_test, { desc = '[G]o [O]utput Test ' })

  local extmark_ids = {}
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.go',
    callback = function()
      Clean_up_prev_job(job_id)

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
            table.insert(test_state.all_output, decoded)

            if ignored_actions[decoded.Action] then
              goto continue
            end

            if decoded.Action == 'run' then
              add_golang_test(bufnr, test_state, decoded)
              goto continue
            end

            if decoded.Action == 'output' then
              if decoded.Test then
                add_golang_output(test_state, decoded)
              end
              goto continue
            end

            local test = test_state.tests[make_key(decoded)]
            if not test then
              goto continue
            end

            if decoded.Action == 'pass' then
              mark_outcome(test_state, decoded)

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
              mark_outcome(test_state, decoded)
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
          on_exit_fn(test_state, bufnr)
        end,
      })
    end,
  })
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

local attach_one_test = function()
  local test_name = Get_enclosing_test()
  make_notify(string.format('Attaching test: %s', test_name))
  local command = { 'go', 'test', './...', '-json', '-v', '-run', test_name }
  group = vim.api.nvim_create_augroup('live_go_test_group', { clear = true })
  ns = vim.api.nvim_create_namespace 'live_go_test_ns'
  attach_to_buffer(vim.api.nvim_get_current_buf(), command)
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

local attach_go_test_one = function()
  clear_previous_group_and_ns_if_exists()
  attach_one_test()
end

vim.api.nvim_create_user_command('GoTestOnSave', attach_go_test_one, {})
vim.api.nvim_create_user_command('GoTestOnSaveAll', attach_go_test_all, {})
vim.api.nvim_create_user_command('GoClearTestOnSave', clear_previous_group_and_ns_if_exists, {})

vim.keymap.set('n', '<leader>gt', attach_go_test_one, { desc = '[T]oggle [G]o Test on save' })
vim.keymap.set('n', '<leader>gc', clear_previous_group_and_ns_if_exists, { desc = '[G]o [C]lear test on save' })

vim.api.nvim_create_user_command('DriveTestOnSaveDev', function()
  vim.env.UKS = 'others'
  vim.env.MODE = 'dev'
  attach_one_test()
end, {})

vim.api.nvim_create_user_command('DriveTestOnSaveStaging', function()
  vim.env.UKS = 'others'
  vim.env.MODE = 'staging'
  attach_one_test()
end, {})

return {}
