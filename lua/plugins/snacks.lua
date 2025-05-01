return {
  'SearidangPa/snacks.nvim',
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
    dashboard = {
      enabled = true,
      preset = {
        keys = {
          { icon = ' ', key = 'f', desc = 'File', action = ":lua Snacks.dashboard.pick('files')" },
          { icon = ' ', key = 'g', desc = 'Grep', action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = '🔱', key = 'h', desc = 'Harpoon', action = ":lua require('custom.snack_harpoon').pick_harpoon()" },
          { icon = '󰒲 ', key = 'L', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
          { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
        },
      },

      sections = {
        { section = 'header' },
        {
          icon = ' ',
          title = 'Recent Files',
          section = 'recent_files',
          indent = 2,
          padding = 1,
          limit = 9,
          filter = function(file)
            local is_in_cwd = vim.startswith(file, vim.fn.getcwd())
            if not is_in_cwd then
              return false
            end
            if vim.fn.isdirectory(file) == 1 then
              return false
            end
            return true
          end,
        },

        {
          icon = '🔱',
          title = 'Harpoon Files',
          section = 'harpoon',
          indent = 2,
          padding = 1,
          limit = 5,
        },
        { icon = ' ', section = 'keys', indent = 2, padding = 1 },

        {
          icon = ' ',
          title = 'Git Status',
          section = 'terminal',
          enabled = function() return Snacks.git.get_root() ~= nil end,
          cmd = 'git status --short --branch --renames',
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 3,
        },
        { section = 'startup' },
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
          height = 0.5,
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
    { '<localleader>f', function() Snacks.picker.files() end, desc = 'Find Files' },
    { '<localleader>g', function() Snacks.picker.grep() end, desc = 'Grep' },
    { '<localleader>r', function() Snacks.picker.lsp_references() end, nowait = true, desc = 'References' },
    { '<localleader>d', function() Snacks.picker.lsp_symbols() end, desc = 'LSP Symbols' },
    { '<localleader>w', function() Snacks.picker.lsp_workspace_symbols() end, desc = 'LSP Workspace Symbols' },
  },
}
