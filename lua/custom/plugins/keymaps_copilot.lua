local function SuggestOneWord()
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']() or ''
  -- Trim leading/trailing spaces
  bar = bar:match '^%s*(.-)%s*$' or ''
  -- Match the first word, or use the entire `bar` if no space/dot is found
  local result = bar:match '^[^ .]+' or bar
  return result
end

local function SuggestLine()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end

local map = vim.keymap.set

map('i', '<C-j>', SuggestOneWord, { expr = true, remap = false })
map('i', '<C-h>', SuggestLine, { expr = true, remap = false })

return {}
