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
  assert(clear_copilot, 'copilot#Clear not found')
  assert(suggestion, 'copilot#GetDisplayedSuggestion not found')
  assert(suggestion.text, 'copilot#GetDisplayedSuggestion.text not found')

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

  -- Show matches with virtual text
  local ns = vim.api.nvim_create_namespace 'copilot_jump'
  local line = vim.fn.line '.' - 1
  local current_line = vim.api.nvim_get_current_line()
  local current_col = #current_line

  -- First, display the suggestion text
  clear_copilot()
  vim.api.nvim_buf_set_extmark(0, ns, line, current_col, {
    virt_text = { { text, 'Comment' } },
    virt_text_pos = 'overlay',
  })

  -- Create labels for each match
  local labels = {}
  for i, pos in ipairs(matches) do
    local label = string.char(string.byte 'a' + i - 1)
    labels[label] = pos
    vim.api.nvim_buf_set_extmark(0, ns, line, current_col + pos - 1, {
      virt_text = { { label, 'Search' } },
      virt_text_pos = 'right_align',
    })
  end

  -- Get user's choice and handle it immediately
  local ok, choice = pcall(function()
    return string.char(vim.fn.getchar())
  end)

  -- Clean up virtual text
  vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)

  if ok and labels[choice] then
    local partial = string.sub(text, 1, labels[choice])
    vim.api.nvim_feedkeys(partial, 'n', false)
  end
end

return {
  'github/copilot.vim',
  config = function()
    local map = vim.keymap.set
    vim.g.copilot_no_tab_map = true

    map('i', '<M-a>', accept_until_char, { silent = true, desc = 'Accept Copilot until char' })
    map('i', '<M-s>', highlight_jump_accept, { silent = true, desc = 'Accept Copilot and jump' })

    -- ================== Copilot =================
    map('i', '<C-;>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })
    map('i', '<C-l>', accept_line, { expr = true, silent = true, desc = 'Accept Copilot Line' })
    map('i', '<M-Enter>', accept_with_newline, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
  end,
}
