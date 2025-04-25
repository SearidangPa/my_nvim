return {
  'SearidangPa/hopcopilot.nvim',
  lazy = true,
  event = 'VeryLazy',
  dependencies = {
    { 'github/copilot.vim', version = '*' },
  },
  config = function()
    local hopcopilot = require 'hopcopilot'
    hopcopilot.setup()
    vim.keymap.set('i', '<M-s>', hopcopilot.hop_copilot, { silent = true, desc = 'hop copilot' })
    vim.keymap.set('i', '<D-s>', hopcopilot.hop_copilot, { silent = true, desc = 'hop copilot' })

    ---@class copilot_accept_opts
    ---@field only_one_line boolean

    ---@param opts copilot_accept_opts
    local function accept(opts)
      local only_one_line = opts.only_one_line or false
      local accept
      if only_one_line then
        accept = vim.fn['copilot#AcceptLine']
      else
        accept = vim.fn['copilot#Accept']
      end
      assert(accept, 'copilot accept or accept line not found')
      local res = accept()
      local cursor_pos = vim.api.nvim_win_get_cursor(0)
      local next_line = cursor_pos[1]
      local next_line_content = vim.api.nvim_buf_get_lines(0, next_line, next_line + 1, false)
      local is_next_line_empty = next_line_content[1] and next_line_content[1]:match '^%s*$'
      if is_next_line_empty then
        vim.api.nvim_feedkeys(res .. '\n', 'n', false)
      else
        vim.api.nvim_feedkeys(res, 'n', false)
      end
    end

    -- ctrl-l does not work on windows terminal for some reason
    local map = vim.keymap.set
    map('i', '<C-l>', function() accept { only_one_line = true } end, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<M-l>', function() accept { only_one_line = true } end, { expr = true, silent = true, desc = 'Accept Copilot' })

    map('i', '<D-y>', function() accept(false) end, { expr = true, silent = true, desc = 'Accept Copilot' })
    map('i', '<M-y>', function() accept(false) end, { expr = true, silent = true, desc = 'Accept Copilot' })
  end,
}
