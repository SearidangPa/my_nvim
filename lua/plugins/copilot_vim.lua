local function accept()
  local accept = vim.fn['copilot#Accept']
  if accept then
    local res = accept()
    vim.api.nvim_feedkeys(res, 'n', false)
  end
end

local function accept_with_newline()
  local accept = vim.fn['copilot#Accept']
  if accept then
    local res = accept()
    res = res .. '\r'
    vim.api.nvim_feedkeys(res, 'n', false)
  end
end

local function accept_word()
  local accept_word = vim.fn['copilot#AcceptWord']
  if accept_word then
    local res = accept_word()
    vim.api.nvim_feedkeys(res, 'n', false)
  end
end

local function accept_line()
  local accept_line = vim.fn['copilot#AcceptLine']
  if accept_line then
    local res = accept_line()
    vim.api.nvim_feedkeys(res, 'n', false)
  end
end

-- ================== experiment =================
local function accept_until_char()
  local char = vim.fn.getchar()
  -- Convert numeric char code to string
  char = type(char) == 'number' and vim.fn.nr2char(char) or char

  local accept = vim.fn['copilot#Accept']
  if accept == nil then
    return
  end

  -- Match everything until (but not including) the target character
  local pattern = '[^' .. vim.fn.escape(char, '^$()%.[]*+-?') .. ']*'
  print('Pattern:', pattern)

  local res = vim.fn['copilot#Accept']('', pattern)
  vim.api.nvim_feedkeys(res, 'n', false)
end

return {
  'github/copilot.vim',
  config = function()
    local map = vim.keymap.set
    vim.g.copilot_no_tab_map = true

    map('i', '<C-x>', accept_until_char, { silent = true, desc = 'Accept Copilot until char' })

    -- ================== Copilot =================
    map('i', '<C-l>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })
    map('i', '<M-Right>', accept_line, { expr = true, silent = true, desc = 'Accept Copilot Line' })
    map('i', '<M-Enter>', accept_with_newline, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
  end,
}
