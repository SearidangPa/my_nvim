local function accept()
  local accept = vim.fn['copilot#Accept']
  assert(accept, 'copilot#Accept not found')
  local res = accept()
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_with_indent()
  local accept = vim.fn['copilot#Accept']
  assert(accept, 'copilot#Accept not found')
  local res = accept()
  res = res .. '\r'
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_word()
  local accept_word = vim.fn['copilot#AcceptWord']
  assert(accept_word, 'copilot#AcceptWord not found')
  local res = accept_word()
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_line_with_indent()
  local accept_line = vim.fn['copilot#AcceptLine']
  assert(accept_line, 'copilot#AcceptLine not found')
  local res = accept_line()
  res = res .. '\r'
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_until_char()
  local char = vim.fn.nr2char(vim.fn.getchar())

  local suggestion = vim.fn['copilot#GetDisplayedSuggestion']()
  local clear_copilot = vim.fn['copilot#Clear']
  assert(clear_copilot, 'copilot#Clear not found')
  assert(suggestion, 'copilot#GetDisplayedSuggestion not found')

  local text = suggestion.text
  local index = string.find(text, char, 1, true)
  if index then
    local partial = string.sub(text, 1, index)
    vim.api.nvim_feedkeys(partial, 'n', false)
    clear_copilot()
  end
end

local parse_suggestion = function(text, char)
  local matches = {}
  local start = 1
  local lower_char = string.lower(char)
  local upper_char = string.upper(char)
  while true do
    local index_lower = string.find(text, lower_char, start, true)
    local index_upper = string.find(text, upper_char, start, true)

    local index
    if index_lower and index_upper then
      index = math.min(index_lower, index_upper)
    else
      index = index_lower or index_upper
    end
    if not index then
      break
    end
    table.insert(matches, index)
    start = index + 1
  end
  return matches
end

local function hightlight_label_for_jump(matches, text)
  vim.api.nvim_set_hl(0, 'LabelHighlight', { fg = '#5097A4' })
  local ns = vim.api.nvim_create_namespace 'copilot_jump'
  local line = vim.fn.line '.' - 1
  local current_col = vim.fn.col '.' - 1

  local labels = {}
  local virt_text = {}
  local prev_pos = 1

  for i, pos in ipairs(matches) do
    if pos > prev_pos then
      table.insert(virt_text, { string.sub(text, prev_pos, pos - 1), 'CopilotSuggestion' })
    end

    local label = string.char(string.byte 'a' + i - 1)
    labels[label] = pos
    table.insert(virt_text, { label, 'LabelHighlight' })

    prev_pos = pos + 1
  end

  if prev_pos <= #text then
    table.insert(virt_text, { string.sub(text, prev_pos), 'CopilotSuggestion' })
  end
  vim.api.nvim_buf_set_extmark(0, ns, line, current_col, {
    virt_text = virt_text,
    virt_text_pos = 'overlay',
  })
  vim.cmd 'redraw'

  return labels, ns
end

local function jump_from_user_choice(labels, ns, text)
  local choice = vim.fn.nr2char(vim.fn.getchar())
  local pos = labels[choice]
  if pos then
    local partial = string.sub(text, 1, pos)
    vim.api.nvim_feedkeys(partial, 'n', false)
  end
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

local function highlight_jump_accept()
  local char = vim.fn.nr2char(vim.fn.getchar())
  local suggestion = vim.fn['copilot#GetDisplayedSuggestion']()
  local text = suggestion.text
  assert(suggestion, 'copilot#GetDisplayedSuggestion not found')
  assert(text, 'suggestion text not found')

  local matches = parse_suggestion(text, char)
  if #matches == 0 then
    return
  end

  if #matches == 1 then
    local partial = string.sub(text, 1, matches[1])
    vim.api.nvim_feedkeys(partial, 'n', false)
    return
  end
  local labels, ns = hightlight_label_for_jump(matches, text)
  jump_from_user_choice(labels, ns, text)
end

Map_accept_line_copilot = function()
  vim.keymap.set('i', '<C-l>', function()
    local accept_line = vim.fn['copilot#AcceptLine']
    if not accept_line then
      return
    end
    local res = accept_line()
    vim.api.nvim_feedkeys(res, 'n', false)
  end, { expr = true, silent = true, desc = 'Accept Copilot Line' })
end

return {
  'github/copilot.vim',
  config = function()
    local map = vim.keymap.set
    vim.g.copilot_no_tab_map = true

    map('i', '<D-a>', accept_until_char, { silent = true, desc = 'Accept Copilot until char' })
    map('i', '<D-s>', highlight_jump_accept, { silent = true, desc = 'Accept Copilot and jump' })

    map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })
    -- ================== Custom mappings ==================
    map('i', '<M-y>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<M-Enter>', accept_with_indent, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
    Map_accept_line_copilot()

    map('i', '<C-Enter>', accept_line_with_indent, { expr = true, silent = true, desc = 'Accept Copilot Line' })
  end,
}
