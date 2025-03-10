return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },

  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}

    vim.keymap.set('n', '<localleader>a', function() harpoon:list():add() end, { desc = 'harpoon [A]dd' })
    vim.keymap.set('n', '<localleader>p', function() harpoon:list():prepend() end, { desc = 'harpoon [P]repend' })
    vim.keymap.set('n', '<localleader>l', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon [L]ist' })
    vim.keymap.set('n', '<C-S-P>', function() harpoon:list():prev() end)
    vim.keymap.set('n', '<C-S-N>', function() harpoon:list():next() end)

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
      vim.keymap.set('n', string.format('<localleader>%d', idx), function() harpoon:list():select(idx) end, { desc = string.format('harpoon %d', idx) })
    end

    harpoon:extend {
      UI_CREATE = function(cx)
        vim.keymap.set('n', '<C-v>', function() harpoon.ui:select_menu_item { vsplit = true } end, { buffer = cx.bufnr })
      end,
    }
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

    vim.keymap.set('n', '<leader>sp', function() toggle_telescope(harpoon:list()) end, { desc = 'harpoon [S]earch [P]inned' })
  end,
}
