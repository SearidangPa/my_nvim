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

return {
  'github/copilot.vim',
  config = function()
    local map = vim.keymap.set
    vim.g.copilot_no_tab_map = true

    map('i', '<M-a>', accept_until_char, { silent = true, desc = 'Accept Copilot until char' })

    -- ================== Copilot =================
    map('i', '<C-;>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })
    map('i', '<C-l>', accept_line, { expr = true, silent = true, desc = 'Accept Copilot Line' })
    map('i', '<M-Enter>', accept_with_newline, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
  end,
}
