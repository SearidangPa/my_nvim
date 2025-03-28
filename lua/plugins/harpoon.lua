return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },

  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}
    local map = vim.keymap.set

    map('n', '<localleader>ha', function() harpoon:list():add() end, { desc = 'harpoon add at the [B]ack' })
    map('n', '<localleader>l', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon [L]ist' })

    map('n', '<M-[>', function() harpoon:list():next() end, { desc = 'harpoon next' })
    map('n', '<M-]>', function() harpoon:list():prev() end, { desc = 'harpoon prev' })
    map('n', '<M-;>', function() harpoon:list():select(1) end, { desc = 'harpoon select 1' })

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
      map('n', string.format('<localleader>%d', idx), function() harpoon:list():select(idx) end, { desc = string.format('harpoon select %d', idx) })
    end

    local function delete_at_index(fileIndex)
      harpoon.ui:toggle_quick_menu(harpoon:list())
      for _ = 1, fileIndex - 1 do
        vim.cmd 'normal! j'
      end
      vim.cmd 'normal! dd'
      vim.cmd 'w'
    end

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
      map('n', string.format('<localleader>hd%d', idx), function() delete_at_index(idx) end, { desc = string.format('harpoon delete %d', idx) })
    end

    -- Delete the current file from harpoon
    local function delete_current_file(with_toggle_quick_menu)
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

      if fileIndex and vim.fn.has 'win32' == 1 then
        fileIndex = fileIndex - 1
      end

      if fileIndex then
        table.remove(items, fileIndex)
        harpoon.ui:toggle_quick_menu(harpoon:list())
        for _ = 1, fileIndex do
          vim.cmd 'normal! j'
        end
        vim.cmd 'normal! dd'
        vim.cmd 'w'
        if with_toggle_quick_menu then
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end
      end
    end

    map('n', '<localleader>a', function()
      delete_current_file(true)
      harpoon:list():prepend()
    end, { desc = 'harpoon [A]dd' })

    local function add_at_index(idx)
      delete_current_file(true)
      local currentFileRelative = vim.fn.expand '%:.' -- Get the file path relative to working directory
      vim.fn.setreg('*', currentFileRelative .. '\n')
      harpoon.ui:toggle_quick_menu(harpoon:list())
      for _ = 1, idx - 1 do
        vim.cmd 'normal! j'
      end
      vim.cmd 'normal! P'
      vim.cmd 'w'
    end

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
      map('n', string.format('<localleader>h%d', idx), function() add_at_index(idx) end, { desc = string.format('harpoon add at index%d', idx) })
    end

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
