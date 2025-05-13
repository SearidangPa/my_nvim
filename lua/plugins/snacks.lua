return {
  'folke/snacks.nvim',
  lazy = true,
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
    gitbrowse = { enabled = true },
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
    {
      '<localleader>fp',
      function()
        Snacks.picker.files {
          cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
        }
      end,
      desc = 'Find Plugin Files',
    },
    {
      '<localleader>fc',
      function()
        Snacks.picker.files {
          cwd = vim.fn.stdpath 'config',
        }
      end,
      desc = 'Find Neovim Config Files',
    },

    { '<leader>sg', function()
      Snacks.picker.grep {
        cmd = 'rg',
      }
    end, desc = 'Grep' },

    -- === git ===
    { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Log File' },
    { '<leader>gl', function() Snacks.picker.git_log() end, desc = 'Git Log' },
    { '<leader>gb', function() Snacks.picker.git_branches() end, desc = 'Git Branches' },
    { '<leader>gg', function() Snacks.lazygit() end, desc = 'Git Branches' },

    -- === LSP ===
    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
    { 'gD', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto Declaration' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },

    { '<leader>sh', function() Snacks.picker.help() end, desc = 'Help Pages' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps' },

    { '<leader>sr', function() Snacks.picker.resume() end, desc = 'Resume' },
    { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },

    { '<leader>uc', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes' },
    { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },
    { '<leader>s"', function() Snacks.picker.registers() end, desc = 'Registers' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List' },

    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word', mode = { 'n', 'x' } },
    { '<leader>so', function() Snacks.picker.grep_buffers { cmd = 'rg' } end, desc = 'Grep [O]pen Buffers' },
    --- === Most heavily used
    { '<leader>s/', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },
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
    { '<leader>o', function() Snacks.picker.buffers() end, desc = 'Grep Open Buffers' },
    { '<leader>d', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
    { '<leader>r', function()
      Snacks.picker.lsp_references {
        include_declaration = false,
      }
    end, nowait = true, desc = 'References' },
    {
      'gR',
      function()
        Snacks.picker.lsp_references {
          include_declaration = false,
          filter = {
            filter = function(item, _)
              local file_path = item.file
              return not file_path:match 'test'
            end,
          },
        }
      end,
      nowait = true,
      desc = 'References (no tests)',
    },
    { '<leader>w', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
    { '<leader>e', function() Snacks.picker.git_diff() end, desc = 'Git Diff Hunks (Edited)' },
    { '<leader>j', function() Snacks.picker.jumps() end, desc = 'Registers' },
  },
}
