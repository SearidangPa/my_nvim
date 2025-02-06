return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  version = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function()
        return vim.fn.executable 'make' == 1
      end,
    },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    local builtin = require 'telescope.builtin'
    local map = vim.keymap.set

    map('n', '<leader>s/', function()
      builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
        winblend = 10,
        previewer = false,
      })
    end, { desc = '[/] Fuzzily search in current buffer' })

    map('n', '<leader>en', function()
      builtin.find_files {
        cwd = vim.fn.stdpath 'config',
      }
    end, { desc = '[E]dit [N]vim config' })

    map('n', '<leader>ep', function()
      builtin.find_files {
        cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
      }
    end, { desc = '[E]dit [P]lugins' })

    map('n', '<localleader>sg', function()
      builtin.live_grep {
        cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
      }
    end, { desc = '[S]earch Plugin by [G]rep' })

    map('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    map('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    map('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    map('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    map('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })

    -- have not achieved muscle memory for these yet
    map('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
    map('n', '<leader>se', builtin.git_status, { desc = '[S]earch [E]dit (unstaged files)' })
    map('n', '<leader>sj', builtin.jumplist, { desc = '[S]earch [J]umplist' })
    map('n', '<leader>sb', builtin.git_branches, { desc = '[S]earch Git [B]ranches' })

    -- trying out
    map('n', '<leader>st', builtin.treesitter, { desc = '[S]earch [T]reesitter' })
    map('n', '<leader>sc', builtin.git_bcommits, { desc = '[S]earch [C]ommits' })
    map('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    map('n', '<leader>sl', builtin.reloader, { desc = '[S]earch [L]oader' })

    -- useless?
    map('n', '<leader>so', builtin.buffers, { desc = '[S]earch [O]pen Buffers' })
    map('n', '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
    local opts = {
      pickers = {
        help_tags = { theme = 'ivy' },
        find_files = { theme = 'ivy', hidden = true },
        live_grep = { theme = 'ivy' },
        git_status = { theme = 'ivy' },
        jumplist = { theme = 'ivy' },
        treesitter = { theme = 'ivy' },
        git_bcommits = { theme = 'ivy' },
        diagnostics = { theme = 'ivy' },
        lsp_references = { theme = 'ivy' },
        lsp_dynamic_workspace_symbols = { theme = 'ivy' },
        lsp_document_symbols = { theme = 'ivy' },
      },
      defaults = {
        file_ignore_patterns = {
          '.git\\',
          'git/',
        },
        layout_strategy = 'vertical',
        layout_config = {
          width = 0.7,
        },
      },
      extensions = {
        ['ui-select'] = {
          require('telescope.themes').get_dropdown(),
        },
        fzf = {},
      },
    }
    require('telescope').setup(opts)
    require('telescope').load_extension 'fzf'
    require('telescope').load_extension 'ui-select'

    require('config.telescope_multigrep').setup()
  end,
}
