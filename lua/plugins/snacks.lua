return {
  'folke/snacks.nvim',
  lazy = true,
  event = 'BufEnter',
  version = '*',

  ---@type snacks.Config
  opts = {
    ---@type table<string, snacks.win.Config>
    styles = {
      -- style for prompting input box
      input = {
        relative = 'editor',
        row = 10,
        b = {
          completion = true,
        },
      },
    },
    input = {
      enabled = true,
    },
    bigfile = { enabled = true },
    indent = { enabled = true },
    picker = {
      previewers = {
        -- diff hunk preview: use delta instead of builtin
        diff = {
          builtin = false, -- disable Neovim buffer diff
          cmd = { 'delta' }, -- external diff command
        },
        -- git status preview: run 'git diff HEAD' through delta
        git = {
          builtin = false, -- disable Neovim buffer preview
          args = { '-c', 'core.pager=delta' }, -- instruct git to use delta as pager
        },
      },

      enabled = true,
      layout = {
        preset = 'ivy_split',
        layout = {
          height = 0.35,
        },
      },
    },
  },

  keys = {
    -- === git ===
    { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Log File' },
    { '<leader>gl', function() Snacks.picker.git_log() end, desc = 'Git Log' },
    { '<leader>gd', function() Snacks.picker.git_diff() end, desc = 'Git Diff (Hunks)' },
    { '<leader>gb', function() Snacks.picker.git_branches() end, desc = 'Git Branches' },
    { '<leader>gg', function() Snacks.lazygit() end, desc = 'Git Branches' },

    -- === LSP ===
    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
    { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto Declaration' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },
    { '<leader>D', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto T[y]pe Definition' },

    { '<leader>uc', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes' },

    -- === Help, Keymaps ===
    { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },
    { '<leader>sh', function() Snacks.picker.help() end, desc = 'Help Pages' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps' },

    -- === search ===
    { '<leader>s/', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },
    { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo History' },
    { '<leader>sr', function() Snacks.picker.resume() end, desc = 'Resume' },
    { '<leader>so', function() Snacks.picker.grep_buffers { cmd = 'rg' } end, desc = 'Grep Open Buffers' },

    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word', mode = { 'n', 'x' } },

    -- === search registers, autocmds, command_history, marks, qflist ===
    { '<leader>s"', function() Snacks.picker.registers() end, desc = 'Registers' },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'Registers' },
    { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List' },

    { '<leader>o', function() Snacks.picker.buffers() end, desc = 'Grep Open Buffers' },
    {
      '<leader>f',
      function()
        require 'snacks'
        Snacks.picker.files {
          cmd = 'fd',
        }
      end,
      desc = 'Find Files',
    },
    { '<leader>sg', function()
      Snacks.picker.grep {
        cmd = 'rg',
      }
    end, desc = 'Grep' },
    { '<leader>r', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References' },
    { '<leader>d', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
    { '<leader>w', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
  },
}
