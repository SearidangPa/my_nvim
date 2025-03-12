return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },

  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}
    local map = vim.keymap.set

    map('n', '<localleader>a', function() harpoon:list():prepend() end, { desc = 'harpoon [A]dd' })
    map('n', '<localleader>l', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon [L]ist' })
    map('n', '<C-S-P>', function() harpoon:list():prev() end)
    map('n', '<C-S-N>', function() harpoon:list():next() end)

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
      map('n', string.format('<localleader>%d', idx), function() harpoon:list():select(idx) end, { desc = string.format('harpoon select %d', idx) })

      map('n', string.format('<leader>%d', idx), function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
        for _ = 1, idx - 1 do
          vim.cmd 'normal! j'
        end
        vim.cmd 'normal! dd'
        vim.cmd 'w'
      end, { desc = string.format('harpoon remove %d', idx) })
    end

    harpoon:extend {
      UI_CREATE = function(cx)
        map('n', '<C-v>', function() harpoon.ui:select_menu_item { vsplit = true } end, { buffer = cx.bufnr })
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

    map('n', '<C-p>', function() toggle_telescope(harpoon:list()) end, { desc = 'harpoon Search [P]inned' })
  end,
}
