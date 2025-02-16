local function accept()
  local accept = vim.fn['copilot#Accept']
  assert(accept, 'copilot#Accept not found')
  local res = accept()
  vim.api.nvim_feedkeys(res, 'n', false)
end

local function accept_with_newline()
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

local function accept_line()
  local accept_line = vim.fn['copilot#AcceptLine']
  assert(accept_line, 'copilot#AcceptLine not found')
  local res = accept_line()
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

local function highlight_jump_accept()
  local char = vim.fn.nr2char(vim.fn.getchar())
  local suggestion = vim.fn['copilot#GetDisplayedSuggestion']()
  local clear_copilot = vim.fn['copilot#Clear']
  assert(suggestion, 'copilot#GetDisplayedSuggestion not found')
  assert(suggestion.text, 'copilot#GetDisplayedSuggestion.text not found')
  assert(clear_copilot, 'copilot#Clear not found')

  local text = suggestion.text
  local matches = {}
  local start = 1
  while true do
    local index = string.find(text, char, start, true)
    if not index then
      break
    end
    table.insert(matches, index)
    start = index + 1
  end
  assert(#matches > 0, 'No matches found')

  local ns = vim.api.nvim_create_namespace 'copilot_jump'
  local line = vim.fn.line '.' - 1
  local current_col = vim.fn.col '.' - 1

  local labels = {}
  local virt_text = {}
  local prev_pos = 1

  vim.api.nvim_set_hl(0, 'LabelHighlight', { fg = '#5097A4' })

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
  print('Virtual text prepared:', vim.inspect(virt_text))
  vim.api.nvim_buf_set_extmark(0, ns, line, current_col, {
    virt_text = virt_text,
    virt_text_pos = 'overlay',
  })

  vim.cmd 'redraw'
  print('Choose label (a-' .. string.char(string.byte 'a' + #matches - 1) .. '):')
  local choice = vim.fn.nr2char(vim.fn.getchar())

  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  local pos = labels[choice]
  if pos then
    local partial = string.sub(text, 1, pos)
    vim.api.nvim_feedkeys(partial, 'n', false)
    clear_copilot()
  end
end

return {
  'github/copilot.vim',
  config = function()
    local map = vim.keymap.set
    vim.g.copilot_no_tab_map = true

    map('i', '<M-a>', accept_until_char, { silent = true, desc = 'Accept Copilot until char' })
    map('i', '<M-s>', highlight_jump_accept, { silent = true, desc = 'Accept Copilot and jump' })

    map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })
    -- ================== Custom mappings ==================
    map('i', '<C-l>', accept_line, { expr = true, silent = true, desc = 'Accept Copilot Line' })
    map('i', '<M-l>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<M-Enter>', accept_with_newline, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
  end,
}
