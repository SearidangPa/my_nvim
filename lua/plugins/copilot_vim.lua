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

local function accept_highlight_and_jump()
  local char = vim.fn.nr2char(vim.fn.getchar())

  local suggestion = vim.fn['copilot#GetDisplayedSuggestion']()
  local clear_copilot = vim.fn['copilot#Clear']
  assert(clear_copilot, 'copilot#Clear not found')
  assert(suggestion, 'copilot#GetDisplayedSuggestion not found')

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

  if #matches == 0 then
    return
  end

  -- Show matches with virtual text
  local ns = vim.api.nvim_create_namespace 'copilot_jump'
  local line = vim.fn.line '.' - 1
  local col = vim.fn.col '.' - 1

  -- Clear existing virtual text
  vim.api.nvim_buf_clear_namespace(0, ns, line, line + 1)

  -- Create labels for each match
  local labels = {}
  for i, pos in ipairs(matches) do
    local label = string.char(string.byte 'a' + i - 1)
    labels[label] = pos
    vim.api.nvim_buf_set_extmark(0, ns, line, col + pos - 1, {
      virt_text = { { label, 'Search' } },
      virt_text_pos = 'overlay',
    })
  end

  -- Get user input for jump
  vim.cmd 'redraw'
  local jump_char = vim.fn.nr2char(vim.fn.getchar())

  -- Clear virtual text
  vim.api.nvim_buf_clear_namespace(0, ns, line, line + 1)

  -- Jump to selected position
  local jump_pos = labels[jump_char]
  if jump_pos then
    local partial = string.sub(text, 1, jump_pos)
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
    map('i', '<M-s>', accept_highlight_and_jump, { silent = true, desc = 'Accept Copilot and jump' })

    -- ================== Copilot =================
    map('i', '<C-;>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })
    map('i', '<C-l>', accept_line, { expr = true, silent = true, desc = 'Accept Copilot Line' })
    map('i', '<M-Enter>', accept_with_newline, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
  end,
}
