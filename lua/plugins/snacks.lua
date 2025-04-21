return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = { enabled = true },
    indent = { enabled = true },
    picker = {
      enabled = true,
      layout = {
        preset = 'ivy',
        layout = {
          width = 0,
          height = 0.7,
        },
      },
    },
    quickfile = { enabled = true },
  },

  keys = {
    { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Projects' },

    -- === git ===
    { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Log File' },
    { '<leader>gl', function() Snacks.picker.git_log() end, desc = 'Git Log' },
    { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazygit' },
    { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Git Browse', mode = { 'n', 'v' } },

    -- === search in buffers ===
    { '<leader>s/', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },
    { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo History' },
    { '<leader>sR', function() Snacks.picker.resume() end, desc = 'Resume' },
    { '<leader>sB', function() Snacks.picker.grep_buffers() end, desc = 'Grep Open Buffers' },

    -- === search registers, autocmds, command_history, marks, qflist ===
    { '<leader>s"', function() Snacks.picker.registers() end, desc = 'Registers' },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'Registers' },
    { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },
    { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List' },

    { '<leader>ss', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
    { '<leader>uc', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes' },

    -- LSP
    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
  },

  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...) Snacks.debug.inspect(...) end
        _G.bt = function() Snacks.debug.backtrace() end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        Snacks.toggle.dim():map '<leader>td'
      end,
    })
  end,
}
