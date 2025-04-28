return {
  'ThePrimeagen/harpoon',
  lazy = true,
  event = 'VeryLazy',
  branch = 'harpoon2',
  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}
    local map = vim.keymap.set

    map('n', '<localleader>ha', function() harpoon:list():add() end, { desc = 'harpoon add at the [B]ack' })
    map('n', '<M-l>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon [L]ist' })
    map('n', '<D-l>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon [L]ist' })

    map('n', '<D-[>', function() harpoon:list():prev() end, { desc = 'harpoon next' })
    map('n', '<M-[>', function() harpoon:list():prev() end, { desc = 'harpoon next' })
    map('n', '<M-]>', function() harpoon:list():next() end, { desc = 'harpoon prev' })
    map('n', '<D-]>', function() harpoon:list():next() end, { desc = 'harpoon prev' })

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6 } do
      map('n', string.format('<leader>%d', idx), function() harpoon:list():select(idx) end, { desc = string.format('harpoon select %d', idx) })
    end

    local function delete_at_index(fileIndex)
      harpoon.ui:toggle_quick_menu(harpoon:list())
      for _ = 1, fileIndex - 1 do
        vim.cmd 'normal! j'
      end
      vim.cmd 'normal! dd'
      vim.cmd 'w'
    end

    for _, idx in ipairs { 1, 2, 3, 4, 5 } do
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

      if fileIndex then
        delete_at_index(fileIndex)
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

    for _, idx in ipairs { 1, 2, 3, 4, 5 } do
      map('n', string.format('<localleader>h%d', idx), function() add_at_index(idx) end, { desc = string.format('harpoon add at index%d', idx) })
    end

    local function toggle_snack(harpoon_files)
      local file_paths = {}
      for _, item in ipairs(harpoon_files.items) do
        table.insert(file_paths, item.value)
      end

      require('snacks.picker').select(file_paths, {
        prompt = 'Harpoon',
        format_item = function(item) return vim.fn.fnamemodify(item, ':t') end,
        kind = 'Harpoon',
      }, function(choice, idx)
        if choice then
          vim.cmd('edit ' .. choice)
        end
      end)
    end

    map('n', '<C-e>', function() toggle_snack(harpoon:list()) end, { desc = 'harpoon [E]xplore' })
  end,
}
