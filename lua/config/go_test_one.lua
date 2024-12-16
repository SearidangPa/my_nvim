require 'config.find_test_line'
require 'config.floating_window'
local ns = vim.api.nvim_create_namespace 'live_test'
local ts_utils = require 'nvim-treesitter.ts_utils'
local get_node_text = vim.treesitter.get_node_text

function Go_test_Output(state)
  assert(state.tests, vim.inspect(state))
  ---@diagnostic disable-next-line: redefined-local
  local testLine, _ = GetEnclosingFunctionName()
  for _, test in pairs(state.tests) do
    if test.line == testLine - 1 then
      Create_floating_window(test.output, 0, -1)
    end
  end
end

function GetEnclosingFunctionName()
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

local attach_to_buffer = function(bufnr, command, testLine)
  local state = {
    bufnr = bufnr,
    tests = {},
  }

  vim.api.nvim_buf_create_user_command(bufnr, 'GoTestOutput', function()
    Go_test_Output(state)
  end, {})

  local make_key = function(entry)
    assert(entry.Package, 'Must have package name' .. vim.inspect(entry))
    if not entry.Test then
      return entry.Package
    end
    assert(entry.Test, 'Must have test name' .. vim.inspect(entry))
    return string.format('%s/%s', entry.Package, entry.Test)
  end

  local add_golang_test = function(entry)
    state.tests[make_key(entry)] = {
      name = entry.Test,
      line = testLine - 1,
      output = {},
    }
  end

  local add_golang_output = function(entry)
    assert(state.tests, vim.inspect(state))
    table.insert(state.tests[make_key(entry)].output, vim.trim(entry.Output))
  end

  local mark_success = function(entry)
    local test = state.tests[make_key(entry)]
    if not test then
      return
    end
    test.success = entry.Action == 'pass'
  end

  local group = vim.api.nvim_create_augroup('teej-automagic', { clear = true })
  local ignored_actions = {
    pause = true,
    cont = true,
    start = true,
    skip = true,
  }

  local extmark_id = -1
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.go',
    callback = function()
      vim.fn.jobstart(command, {
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

            if ignored_actions[decoded.Action] then
              goto continue
            end

            if decoded.Action == 'run' then
              add_golang_test(decoded)
              goto continue
            end

            if decoded.Action == 'output' then
              if decoded.Test then
                add_golang_output(decoded)
              end
              goto continue
            end

            if decoded.Action == 'pass' or decoded.Action == 'fail' then
              mark_success(decoded)
              local test = state.tests[make_key(decoded)]
              if not test then
                goto continue
              end
              if not test.success then
                goto continue
              end

              if extmark_id ~= -1 then
                vim.api.nvim_buf_del_extmark(bufnr, ns, extmark_id)
              end

              local current_time = os.date '%H:%M:%S'
              extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, test.line, -1, {
                virt_text = {
                  { string.format('%s %s', '✅', current_time) },
                },
                virt_lines_leftcol = true,
              })
              goto continue
            end

            print('Failed to handle: ' .. line)
            ::continue::
          end
        end,

        on_exit = function()
          print 'Tests finished'
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
        end,
      })
    end,
  })
end

vim.api.nvim_create_user_command('GoTestOnSave', function()
  local bufnr = vim.api.nvim_get_current_buf()
  local line, testName = GetEnclosingFunctionName()
  if not testName then
    print 'Not in a function'
    return
  end

  if not string.match(testName, 'Test_') then
    print 'Not a test function'
    return
  end

  print('Attaching test: ' .. testName)

  local command = { 'go', 'test', './...', '-json', '-v', '-run', testName }
  attach_to_buffer(bufnr, command, line)
end, {})

-- unattach the autocommand
vim.api.nvim_create_user_command('StopGoTestOnSave', function()
  vim.api.nvim_del_augroup_by_name 'teej-automagic'
  vim.api.nvim_buf_clear_namespace(vim.api.nvim_get_current_buf(), ns, 0, -1)
  vim.diagnostic.reset()
end, {})

return {}
