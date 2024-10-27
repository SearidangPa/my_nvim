return {
  {
    {
      'L3MON4D3/LuaSnip',
      config = function()
        require('luasnip.loaders.from_lua').load { paths = { 'C:\\Users\\dangs\\AppData\\Local\\nvim\\snippets\\' } }
        local ls = require 'luasnip'

        vim.keymap.set({ 'i' }, '<C-K>', function()
          ls.expand()
        end, { silent = true })
        vim.keymap.set({ 'i', 's' }, '<C-L>', function()
          ls.jump(1)
        end, { silent = true })
        vim.keymap.set({ 'i', 's' }, '<C-J>', function()
          ls.jump(-1)
        end, { silent = true })
      end,
    },

    {
      'ThePrimeagen/harpoon',
      branch = 'harpoon2',
      dependencies = { 'nvim-lua/plenary.nvim' },

      config = function()
        local harpoon = require 'harpoon'
        harpoon:setup {}

        -- basic telescope configuration
        local conf = require('telescope.config').values
        local function toggle_telescope(harpoon_files)
          local file_paths = {}
          for _, item in ipairs(harpoon_files.items) do
            table.insert(file_paths, item.value)
          end

          require('telescope.pickers')
            .new({}, {
              prompt_title = 'Harpoon',
              finder = require('telescope.finders').new_table {
                results = file_paths,
              },
              previewer = conf.file_previewer {},
              sorter = conf.generic_sorter {},
            })
            :find()
        end

        vim.keymap.set('n', '<leader>a', function()
          harpoon:list():add()
        end, { desc = 'add to harpoon' })

        vim.keymap.set('n', '<leader>1', function()
          harpoon:list():select(1)
        end, { desc = 'harpoon 1' })

        vim.keymap.set('n', '<leader>2', function()
          harpoon:list():select(2)
        end, { desc = 'harpoon 2' })

        vim.keymap.set('n', '<leader>3', function()
          harpoon:list():select(3)
        end, { desc = 'harpoon 3' })

        vim.keymap.set('n', '<leader>4', function()
          harpoon:list():select(4)
        end, { desc = 'harpoon 4' })

        vim.keymap.set('n', '<leader>fh', function()
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end, { desc = 'Harpoon (Default)' })

        -- Toggle previous & next buffers stored within Harpoon list
        vim.keymap.set('n', '<C-p>', function()
          harpoon:list():prev()
        end, { desc = 'prev in harpoon' })
        vim.keymap.set('n', '<C-n>', function()
          harpoon:list():next()
        end, { desc = 'next in harpoon' })

        vim.keymap.set('n', '<C-e>', function()
          toggle_telescope(harpoon:list())
        end, { desc = 'Open harpoon window' })
      end,
    },
  },
}
