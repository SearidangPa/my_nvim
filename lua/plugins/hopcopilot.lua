return {
  {
    'github/copilot.vim',
    lazy = true,
    event = 'VeryLazy',
  },
  {
    'SearidangPa/hopcopilot.nvim',
    lazy = true,
    event = 'VeryLazy',
    config = function()
      local hopcopilot = require 'hopcopilot'
      hopcopilot.setup()
      vim.keymap.set('i', '<M-s>', hopcopilot.hop_copilot, { silent = true, desc = 'hop copilot' })
      vim.keymap.set('i', '<D-s>', hopcopilot.hop_copilot, { silent = true, desc = 'hop copilot' })

      ---@class copilot_accept_opts
      ---@field only_one_line boolean
      ---@field no_indentation boolean

      ---@param opts copilot_accept_opts
      local function accept(opts)
        local no_indentation = opts.no_indentation or false
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
        if is_next_line_empty and not no_indentation then
          res = res .. '\n'
        end
        vim.api.nvim_feedkeys(res, 'n', false)
      end

      -- ctrl-l does not work on windows terminal for some reason
      local map = vim.keymap.set
      map('i', '<C-l>', function() accept { no_indentation = true, only_one_line = true } end, { expr = true, silent = true, desc = 'Accept Copilot' })
      map('i', '<M-l>', function() accept { no_indentation = true, only_one_line = true } end, { expr = true, silent = true, desc = 'Accept Copilot' })
      map('i', '<D-y>', function() accept {} end, { expr = true, silent = true, desc = 'Accept Copilot' })
      map('i', '<M-y>', function() accept {} end, { expr = true, silent = true, desc = 'Accept Copilot' })
    end,
  },
}
