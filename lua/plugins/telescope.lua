return {
  'nvim-telescope/telescope.nvim',
  event = 'VimEnter',
  version = false,
  dependencies = {
    'nvim-lua/plenary.nvim',
    {
      'nvim-telescope/telescope-fzf-native.nvim',
      build = 'make',
      cond = function() return vim.fn.executable 'make' == 1 end,
    },
    { 'nvim-telescope/telescope-dap.nvim' },
    { 'nvim-telescope/telescope-ui-select.nvim' },
    { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
  },

  config = function()
    local builtin = require 'telescope.builtin'
    local map = vim.keymap.set
    local map_modes = { 'n', 'v' }
    local function grep_plugins()
      builtin.live_grep {
        cwd = vim.fs.joinpath(tostring(vim.fn.stdpath 'data'), 'lazy'),
      }
    end

    -- help
    map(map_modes, '<leader>sG', grep_plugins, { desc = '[S]earch Plugin by [G]rep' })
    map(map_modes, '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
    map(map_modes, '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })

    -- === jumping around ===
    map(map_modes, '<leader>sO', builtin.buffers, { desc = '[S]earch [O]pen Buffers' })

    map(map_modes, '<leader>sw', builtin.grep_string, { desc = '[S]earch [C]urrent word' })
    map(map_modes, '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })

    -- === git ===
    map(map_modes, '<leader>sc', builtin.git_commits, { desc = '[S]earch [C]ommits' })
    map(map_modes, '<leader>sl', builtin.git_bcommits_range, { desc = '[S]earch last commits on this [L]ine' })

    -- === LSP ===

    local opts = {
      pickers = {
        buffers = { theme = 'ivy' },
        current_buffer_fuzzy_find = { theme = 'ivy' },
        help_tags = { theme = 'ivy' },
        find_files = { theme = 'ivy', hidden = true },
        live_grep = { theme = 'ivy', hidden = true },
        oldfiles = { theme = 'ivy' },
        jumplist = { theme = 'ivy' },
        keymaps = { theme = 'ivy' },
        diagnostics = { theme = 'ivy' },
        lsp_references = { theme = 'ivy', file_ignore_patterns = { '%.pb.go' } },
        lsp_dynamic_workspace_symbols = { theme = 'ivy' },
        lsp_document_symbols = { theme = 'ivy' },
        lsp_incoming_calls = { theme = 'ivy' },
        grep_string = { theme = 'ivy' },
        git_bcommits = { theme = 'ivy' },
        git_commits = { theme = 'ivy' },
        git_bcommits_range = { theme = 'ivy' },
        git_status = { theme = 'ivy' },

        git_branches = {
          theme = 'ivy',
        },
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
    require('telescope').load_extension 'harpoon'
    require('telescope').load_extension 'dap'
    require('telescope').load_extension 'fidget'
    require('config.telescope_multigrep').setup()
  end,
}
