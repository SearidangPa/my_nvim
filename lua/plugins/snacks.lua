return {
  'folke/snacks.nvim',
  event = 'VeryLazy',
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
    quickfile = { enabled = true },
  },

  keys = {
    { '<leader>fp', function() Snacks.picker.projects() end, desc = 'Projects' },
    { '<leader>fg', function() Snacks.picker.git_files() end, desc = 'Find Git Files' },
    {
      '<leader>fp',
      function()
        Snacks.picker.files {
          cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
        }
      end,
      desc = 'Find Plugin Files',
    },
    {
      '<leader>fc',
      function()
        Snacks.picker.files {
          cwd = vim.fn.stdpath 'config',
        }
      end,
      desc = 'Find Neovim Config Files',
    },
    {
      '<leader>sG',
      function()
        Snacks.picker.grep {
          cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
        }
      end,
      desc = 'Grep',
    },

    -- === git ===
    { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Log File' },
    { '<leader>gl', function() Snacks.picker.git_log() end, desc = 'Git Log' },
    { '<leader>gd', function() Snacks.picker.git_diff() end, desc = 'Git Diff (Hunks)' },

    -- === LSP ===
    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
    { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto Declaration' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },
    { '<localleader>D', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto T[y]pe Definition' },

    { '<localleader>uc', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes' },

    -- === Help, Keymaps ===
    { '<localleader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },
    { '<localleader>sh', function() Snacks.picker.help() end, desc = 'Help Pages' },
    { '<localleader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps' },

    -- === search ===
    { '<localleader>s/', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },
    { '<localleader>su', function() Snacks.picker.undo() end, desc = 'Undo History' },
    { '<localleader>sr', function() Snacks.picker.resume() end, desc = 'Resume' },
    { '<localleader>sO', function() Snacks.picker.grep_buffers { cmd = 'rg' } end, desc = 'Grep Open Buffers' },

    { '<localleader>so', function() Snacks.picker.buffers() end, desc = 'Grep Open Buffers' },
    { '<localleader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
    { '<localleader>sw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word', mode = { 'n', 'x' } },

    -- === search registers, autocmds, command_history, marks, qflist ===
    { '<localleader>s"', function() Snacks.picker.registers() end, desc = 'Registers' },
    { '<localleader>sj', function() Snacks.picker.jumps() end, desc = 'Registers' },
    { '<localleader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
    { '<localleader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
    { '<localleader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List' },

    {
      '<localleader>f',
      function()
        require 'snacks'
        Snacks.picker.files {
          cmd = 'fd',
        }
      end,
      desc = 'Find Files',
    },
    { '<localleader>g', function()
      Snacks.picker.grep {
        cmd = 'rg',
      }
    end, desc = 'Grep' },
    { '<localleader>r', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References' },
    { '<localleader>d', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
    { '<localleader>w', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
  },
}
