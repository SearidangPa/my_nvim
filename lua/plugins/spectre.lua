return {
  'nvim-pack/nvim-spectre',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'noib3/nvim-oxi',
  },
  config = function()
    require('spectre').setup {
      color_devicons = true,
      open_cmd = 'tabnew',
      lnum_for_results = true, -- show line number for search/replace results
      highlight = {
        ui = 'String',
        search = 'DiffChange',
        replace = 'DiffDelete',
      },
      mapping = {
        ['tab'] = {
          map = '<Tab>',
          cmd = "<cmd>lua require('spectre').tab()<cr>",
          desc = 'next query',
        },
        ['shift-tab'] = {
          map = '<S-Tab>',
          cmd = "<cmd>lua require('spectre').tab_shift()<cr>",
          desc = 'previous query',
        },
        ['replace_cmd'] = {
          map = '<localleader>cr',
          cmd = "<cmd>lua require('spectre.actions').replace_cmd()<CR>",
          desc = '[C]ommand [R]eplace',
        },
        ['toggle_ignore_case'] = {
          map = 'ti',
          cmd = "<cmd>lua require('spectre').change_options('ignore-case')<CR>",
          desc = 'toggle ignore case',
        },
      },

      find_engine = {
        -- rg is map with finder_cmd
        ['rg'] = {
          cmd = 'rg',
          -- default args
          args = {
            '--color=never',
            '--no-heading',
            '--with-filename',
            '--line-number',
            '--column',
          },
          options = {
            ['ignore-case'] = {
              value = '--ignore-case',
              icon = '[I]',
              desc = 'ignore case',
            },
            ['hidden'] = {
              value = '--hidden',
              desc = 'hidden file',
              icon = '[H]',
            },
            -- you can put any rg search option you want here it can toggle with
            -- show_option function
          },
        },
      },

      default = {
        find = {
          cmd = 'rg',
          options = { 'ignore-case' },
        },
      },

      replace_vim_cmd = 'cdo',
      use_trouble_qf = false, -- use trouble.nvim as quickfix list
      is_block_ui_break = false, -- mapping backspace and enter key to avoid ui break
    }
  end,
}
