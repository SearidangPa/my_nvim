---@param data table
local function make_func_line(data)
  if not data.func_name then
    return ''
  end
  return '❯ ' .. data.func_name
end

---@param filename string
---@param funcLine string
---@param last_seen_filename string
---@param last_seen_func string
---@return table | nil
local function get_virtual_lines(filename, funcLine, last_seen_filename, last_seen_func)
  if funcLine == '' then
    if filename == last_seen_filename then
      return nil
    end
    return { { { '', '' } }, { { filename, 'FileHighlight' } } }
  end

  if filename == last_seen_filename then
    if funcLine == last_seen_func then
      return nil
    end

    return { { { funcLine, '@function' } } }
  end

  if funcLine == last_seen_func then
    return { { { '', '' } }, { { filename, 'FileHighlight' } } }
  end
  return { { { '', '' } }, { { filename, 'FileHighlight' } }, { { funcLine, '@function' } } }
end

---@param parsedMarks table
---@param blackboard_state table
function Add_virtual_lines(parsedMarks, blackboard_state)
  local ns_blackboard = vim.api.nvim_create_namespace 'blackboard_extmarks'
  vim.api.nvim_set_hl(0, 'FileHighlight', { fg = '#5097A4' })
  local last_seen_filename = ''
  local last_seen_func = ''
  blackboard_state.show_context = true

  for lineNum, data in pairs(parsedMarks.virtualLines) do
    local filename = data.filename or ''
    local funcLine = make_func_line(data)
    local extmarkLine = lineNum - 1

    if extmarkLine == 1 then
      vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns_blackboard, 0, 0, {
        virt_lines = { { { filename, 'FileHighlight' } } },
        virt_lines_above = true,
        hl_mode = 'combine',
        priority = 10,
      })
    elseif extmarkLine > 1 then
      local virt_lines = get_virtual_lines(filename, funcLine, last_seen_filename, last_seen_func)
      if virt_lines then
        vim.api.nvim_buf_set_extmark(blackboard_state.blackboard_buf, ns_blackboard, extmarkLine, 0, {
          virt_lines = virt_lines,
          virt_lines_above = true,
          hl_mode = 'combine',
          priority = 10,
        })
      end
    end

    last_seen_filename = filename
    last_seen_func = funcLine
  end
end
