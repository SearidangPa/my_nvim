local function SuggestOneWord()
  vim.fn['copilot#Accept'] ''
  local bar = vim.fn['copilot#TextQueuedForInsertion']()
  return vim.split(bar, '[ .]\zs')[0]
end

local function SuggestLine()
  vim.fn['copilot#Accept'] ''
  return vim.fn['copilot#TextQueuedForInsertion']()
end

local map = vim.keymap.set

map('i', '<m-right>', SuggestOneWord, { expr = true, remap = false })
map('i', '<m-l>', SuggestLine, { expr = true, remap = false })

return {}
