return {
  'lewis6991/gitsigns.nvim',
  lazy = true,
  version = '*',
  event = { 'BufReadCmd', 'LspAttach' },
  opts = {
    signs = {
      add = { text = '+' },
      change = { text = '~' },
      delete = { text = '_' },
      topdelete = { text = '‾' },
      changedelete = { text = '~' },
    },
    on_attach = function(bufnr)
      local gitsigns = require 'gitsigns'

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navigation
      map('n', ']c', function()
        if vim.wo.diff then
          vim.cmd.normal { ']c', bang = true }
        else
          gitsigns.nav_hunk 'next'
        end
      end, { desc = 'Jump to next git [c]hange' })

      map('n', '[c', function()
        if vim.wo.diff then
          vim.cmd.normal { '[c', bang = true }
        else
          gitsigns.nav_hunk 'prev'
        end
      end, { desc = 'Jump to previous git [c]hange' })

      -- Actions
      -- visual mode
      map('v', '<localleader>hs', function() gitsigns.stage_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'stage git hunk' })
      map('v', '<localleader>hr', function() gitsigns.reset_hunk { vim.fn.line '.', vim.fn.line 'v' } end, { desc = 'reset git hunk' })
      -- normal mode
      map('n', '<localleader>hs', gitsigns.stage_hunk, { desc = 'git [s]tage hunk' })
      map('n', '<localleader>hr', gitsigns.reset_hunk, { desc = 'git [r]eset hunk' })
      map('n', '<localleader>hS', gitsigns.stage_buffer, { desc = 'git [S]tage buffer' })
      map('n', '<localleader>hu', gitsigns.stage_hunk, { desc = 'git [u]ndo stage hunk' })
      map('n', '<localleader>hR', gitsigns.reset_buffer, { desc = 'git [R]eset buffer' })
      map('n', '<localleader>hp', gitsigns.preview_hunk, { desc = 'git [p]review hunk' })
      map('n', '<localleader>hb', gitsigns.blame_line, { desc = 'git [b]lame line' })
      map('n', '<localleader>hd', gitsigns.diffthis, { desc = 'git [d]iff against index' })
      map('n', '<localleader>hD', function() gitsigns.diffthis '@' end, { desc = 'git [D]iff against last commit' })
      -- Toggles
      map('n', '<localleader>tD', gitsigns.preview_hunk_inline, { desc = '[T]oggle git show [D]eleted' })
    end,
  },
}
