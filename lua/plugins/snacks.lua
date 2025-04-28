return {
  'folke/snacks.nvim',
  event = 'VeryLazy',

  ---@type snacks.Config
  opts = {
    ---@type table<string, snacks.win.Config>
    styles = {
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
        preset = 'ivy',
        layout = {
          width = 0,
          height = 0.65,
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
    { '<leader>sf', function() Snacks.picker.files() end, desc = 'Find Files' },
    { '<leader>sg', function() Snacks.picker.grep() end, desc = 'Grep' },
    {
      '<leader>sG',
      function()
        Snacks.picker.grep {
          cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
        }
      end,
      desc = 'Grep',
    },

    { '<leader>sO', function() Snacks.picker.grep_buffers() end, desc = 'Grep Open Buffers' },
    { '<leader>so', function() Snacks.picker.buffers() end, desc = 'Grep Open Buffers' },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = 'Diagnostics' },
    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = 'Visual selection or word', mode = { 'n', 'x' } },

    -- === git ===
    { '<leader>gf', function() Snacks.picker.git_log_file() end, desc = 'Git Log File' },
    { '<leader>gl', function() Snacks.picker.git_log() end, desc = 'Git Log' },
    { '<leader>gg', function() Snacks.lazygit() end, desc = 'Lazygit' },
    { '<leader>gd', function() Snacks.picker.git_diff() end, desc = 'Git Diff (Hunks)' },

    -- === search in buffers ===
    { '<leader>s/', function() Snacks.picker.lines() end, desc = 'Buffer Lines' },
    { '<leader>su', function() Snacks.picker.undo() end, desc = 'Undo History' },
    { '<leader>sr', function() Snacks.picker.resume() end, desc = 'Resume' },
    { '<leader>sh', function() Snacks.picker.help() end, desc = 'Help Pages' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = 'Keymaps' },

    -- === search registers, autocmds, command_history, marks, qflist ===
    { '<leader>s"', function() Snacks.picker.registers() end, desc = 'Registers' },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = 'Registers' },
    { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = 'Marks' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = 'Quickfix List' },

    { '<leader>uc', function() Snacks.picker.colorschemes() end, desc = 'Colorschemes' },
    { '<leader>sa', function() Snacks.picker.autocmds() end, desc = 'Autocmds' },

    -- LSP
    { 'gd', function() Snacks.picker.lsp_definitions() end, desc = 'Goto Definition' },
    { 'gD', function() Snacks.picker.lsp_declarations() end, desc = 'Goto Declaration' },
    { 'gI', function() Snacks.picker.lsp_implementations() end, desc = 'Goto Implementation' },
    { '<leader>D', function() Snacks.picker.lsp_type_definitions() end, desc = 'Goto T[y]pe Definition' },
    { '<localleader>r', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References' },
    { '<leader>ds', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
    { '<leader>ws', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
  },

  init = function()
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...) Snacks.debug.inspect(...) end
        _G.bt = function() Snacks.debug.backtrace() end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        require 'snacks'
        Snacks.toggle.dim():map '<leader>td'
      end,
    })
  end,
}
