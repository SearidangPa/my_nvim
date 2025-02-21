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
<<<<<<< Updated upstream
    local map_modes = { 'n', 'v' }

    map(map_modes, '<leader>en', function()
=======
    local function find_files(opts)
>>>>>>> Stashed changes
      builtin.find_files {
        cwd = opts.cwd,
      }
    end
    local function find_files_neovim_config()
      find_files {
        cwd = vim.fn.stdpath 'config',
      }
<<<<<<< Updated upstream
    end, { desc = '[E]dit [N]vim config' })

    map(map_modes, '<leader>ed', function()
      builtin.find_files {
        cwd = '~/Documents/drive/',
      }
    end, { desc = '[E]dit [P]lugins' })

    map(map_modes, '<leader>ep', function()
      builtin.find_files {
        cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
      }
    end, { desc = '[E]dit [P]lugins' })

    map(map_modes, '<localleader>sg', function()
=======
    end
    local function find_files_plugins()
      find_files {
        cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
      }
    end
    local function find_files_drive()
      find_files {
        cwd = '~/Documents/drive/',
      }
    end
    local function grep_plugins()
>>>>>>> Stashed changes
      builtin.live_grep {
        cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
      }
    end

    map('n', '<leader>en', find_files_neovim_config, { desc = '[E]dit [N]vim config' })
    map('n', '<leader>ed', find_files_drive, { desc = '[E]dit [P]lugins' })
    map('n', '<leader>ep', find_files_plugins, { desc = '[E]dit [P]lugins' })
    map('n', '<localleader>sg', grep_plugins, { desc = '[S]earch Plugin by [G]rep' })

    map(map_modes, '<leader>s/', builtin.current_buffer_fuzzy_find, { desc = '[/] Fuzzily search in current buffer' })
    map(map_modes, '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    map(map_modes, '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
    map(map_modes, '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
    map(map_modes, '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
    map(map_modes, '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
    map(map_modes, '<leader>sj', builtin.jumplist, { desc = '[S]earch [J]umplist' })
    map(map_modes, '<leader>sb', builtin.git_branches, { desc = '[S]earch Git [B]ranches' })
    map(map_modes, '<leader>sw', builtin.grep_string, { desc = '[S]earch [C]urrent word' })

    -- have not achieved muscle memory for these yet
    map(map_modes, '<leader>se', builtin.git_status, { desc = '[S]earch [E]dit (unstaged files)' })
    map(map_modes, '<leader>sl', builtin.git_bcommits_range, { desc = '[S]earch [L]ast commits' })
    map(map_modes, '<leader>sr', builtin.git_bcommits, { desc = '[S]earch [R]ecent commits on this branch' })
    map(map_modes, '<leader>sc', builtin.git_commits, { desc = '[S]earch [C]ommits' })

    -- search current buffer with current word
    map(map_modes, '<leader>st', function()
      builtin.current_buffer_fuzzy_find { default_text = vim.fn.expand '<cword>' }
    end, { desc = '[S]earch [T]his word' })

    -- trying out
    map(map_modes, '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
    map(map_modes, '<leader>so', builtin.buffers, { desc = '[S]earch [O]pen Buffers' })

    local opts = {
      pickers = {
        current_buffer_fuzzy_find = { theme = 'ivy' },
        help_tags = { theme = 'ivy' },
        find_files = { theme = 'ivy', hidden = true },
        live_grep = { theme = 'ivy' },
        git_status = { theme = 'ivy' },
        oldfiles = { theme = 'ivy' },
        jumplist = { theme = 'ivy' },
        treesitter = { theme = 'ivy' },
        grep_string = { theme = 'ivy' },
        diagnostics = { theme = 'ivy' },
        lsp_references = { theme = 'ivy', file_ignore_patterns = { '%.pb.go' } },
        lsp_dynamic_workspace_symbols = { theme = 'ivy' },
        lsp_document_symbols = { theme = 'ivy' },
        git_bcommits = { theme = 'ivy' },
        git_commits = { theme = 'ivy' },
        git_bcommits_range = { theme = 'ivy' },
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
