local function trim(s)
  return s:match '^%s*(.-)%s*$'
end

local function SuggestOneWord()
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']()
  bar = trim(bar)
  local result = vim.split(bar, '[ .]')[1]
  return result
end

local function SuggestLine()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end

local map = vim.keymap.set

map('i', '<M-k>', SuggestOneWord, { expr = true, remap = false })
map('i', '<M-l>', SuggestLine, { expr = true, remap = false })

return {}
