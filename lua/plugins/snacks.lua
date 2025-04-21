return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    indent = { enabled = true },
    picker = { enabled = true },
    quickfile = { enabled = true },
  },

  keys = {
    -- out of this world interface
    { '<leader>s/', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },

    { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
    { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Projects' },

    -- git
    { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Log File' },
    { '<leader>gl', function() Snacks.picker.git_log() end, desc = 'Git Log' },

    { '<leader>sB', function() Snacks.picker.grep_buffers() end, desc = 'Grep Open Buffers' },
    -- search
    { '<leader>s"', function() Snacks.picker.registers() end, desc = 'Registers' },
    { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },
    { '<leader>sc', function() Snacks.picker.command_history() end, desc = 'Command History' },
    { '<leader>sC', function() Snacks.picker.commands() end, desc = 'Commands' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
    { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = 'Buffer Diagnostics' },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'Jumps' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
    { '<leader>sp', function() Snacks.picker.lazy() end, desc = 'Search for Plugin Spec' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List' },
    { '<leader>sR', function() Snacks.picker.resume() end, desc = 'Resume' },
    { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo History' },
    { '<leader>uC', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes' },
    -- LSP
    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
    { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto Declaration' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },
    { 'gy', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto T[y]pe Definition' },

    { '<leader>bd', function() Snacks.bufdelete() end, desc = 'Delete Buffer' },
    { '<leader>cR', function() Snacks.rename.rename_file() end, desc = 'Rename File' },
    { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Git Browse', mode = { 'n', 'v' } },
    { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazygit' },
    { '<c-/>', function() Snacks.terminal() end, desc = 'Toggle Terminal' },
    { '<c-_>', function() Snacks.terminal() end, desc = 'which_key_ignore' },
  },

  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...) Snacks.debug.inspect(...) end
        _G.bt = function() Snacks.debug.backtrace() end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
        Snacks.toggle.diagnostics():map '<leader>ud'
        Snacks.toggle.line_number():map '<leader>ul'
        Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>uc'
        Snacks.toggle.inlay_hints():map '<leader>uh'
        Snacks.toggle.indent():map '<leader>ug'
        Snacks.toggle.dim():map '<leader>uD'
      end,
    })
  end,
}
