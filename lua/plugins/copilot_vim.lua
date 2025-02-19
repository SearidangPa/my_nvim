return {
  'SearidangPa/copilot_hop.nvim',
  dependencies = {
    'github/copilot.vim',
  },
  config = function()
    vim.g.copilot_no_tab_map = true

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

    local function accept_line()
      local accept_line = vim.fn['copilot#AcceptLine']
      assert(accept_line, 'copilot#AcceptLine not found')
      local res = accept_line()
      vim.api.nvim_feedkeys(res, 'n', false)
    end

    local function accept_line_with_indent()
      local accept_line = vim.fn['copilot#AcceptLine']
      assert(accept_line, 'copilot#AcceptLine not found')
      local res = accept_line()
      res = res .. '\r'
      vim.api.nvim_feedkeys(res, 'n', false)
    end

    local map = vim.keymap.set
    map('i', '<C-l>', accept_line, { expr = true, silent = true, desc = 'Accept Copilot Line' })
    map('i', '<M-y>', accept, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<C-;>', accept_line_with_indent, { expr = true, silent = true, desc = 'Accept Copilot Line' })
    map('i', '<M-;>', accept_with_indent, { expr = true, silent = true, desc = 'Accept Copilot with newline' })
    map('i', '<M-f>', accept_word, { expr = true, silent = true, desc = 'Accept Copilot Word' })
  end,
}
