return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },

  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}
    local map = vim.keymap.set

    map('n', '<localleader>a', function() harpoon:list():prepend() end, { desc = 'harpoon [A]dd' })
    map('n', '<localleader>b', function() harpoon:list():add() end, { desc = 'harpoon add at the [B]ack' })
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

    -- Delete the current file from harpoon
    local function delete_current_file()
      local currentFileRelative = vim.fn.expand '%:.' -- Get the file path relative to working directory
      local list = harpoon:list()
      local items = list.items

      local fileIndex = nil
      for i, item in ipairs(items) do
        if item.value == currentFileRelative then
          fileIndex = i
          break
        end
      end

      if fileIndex then
        table.remove(items, fileIndex)
        harpoon.ui:toggle_quick_menu(harpoon:list())
        for _ = 1, fileIndex - 1 do
          vim.cmd 'normal! j'
        end
        vim.cmd 'normal! dd'
        vim.cmd 'w'
      end
    end

    map('n', '<localleader>hd', delete_current_file, { desc = 'harpoon delete current file' })

    -- === Telescope ===
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

    map('n', '<C-e>', function() toggle_telescope(harpoon:list()) end, { desc = 'harpoon [E]xplore' })
  end,
}
