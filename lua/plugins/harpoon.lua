return {
  'ThePrimeagen/harpoon',
  lazy = true,
  event = 'VeryLazy',
  branch = 'harpoon2',
  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}
    local map = vim.keymap.set

    local function delete_at_index(fileIndex)
      harpoon.ui:toggle_quick_menu(harpoon:list())
      for _ = 1, fileIndex - 1 do
        vim.cmd 'normal! j'
      end
      vim.cmd 'normal! "_dd'
      vim.cmd 'w'
    end

    local function delete_current_file(with_toggle_quick_menu)
      local currentFileRelative
      if vim.fn.has 'win32' == 1 then
        currentFileRelative = vim.fn.expand '%:p'
      else
        currentFileRelative = vim.fn.expand '%:.'
      end
      currentFileRelative = currentFileRelative:gsub('\\', '/')

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

    local function add_at_index(idx)
      delete_current_file(true)
      local currentFileRelative = vim.fn.expand '%:.' -- Get the file path relative to working directory
      harpoon.ui:toggle_quick_menu(harpoon:list())
      for _ = 1, idx - 1 do
        vim.cmd 'normal! j'
      end
      vim.api.nvim_put({ currentFileRelative, '' }, '', false, true)
      vim.cmd 'w'
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
      }, function(choice, _)
        if choice then
          vim.cmd('edit ' .. choice)
        end
      end)
    end

    map('n', '<C-e>', function() toggle_snack(harpoon:list()) end, { desc = 'harpoon [E]xplore' })

    map('n', '<D-p>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon [L]ist' })
    map('n', '<M-p>', function() harpoon.ui:toggle_quick_menu(harpoon:list()) end, { desc = 'harpoon [L]ist' })

    map('n', '<leader>a', function()
      delete_current_file(true)
      harpoon:list():prepend()
    end, { desc = 'Harpoon [A]dd' })

    map('n', '<leader>ha', function()
      delete_current_file(true)
      harpoon:list():add()
    end, { desc = 'Harpoon [A]dd' })

    for _, idx in ipairs { 1, 2, 3, 4 } do
      map('n', string.format('<leader>h%d', idx), function()
        require('fidget').notify(string.format('harpoon add at index%d', idx))
        add_at_index(idx)
      end, { desc = string.format('harpoon add at index%d', idx) })

      map('n', string.format('<leader>%d', idx), function()
        local item = harpoon:list():get(idx)
        if item then
          vim.cmd('edit ' .. item.value)
        end
      end, { desc = string.format('harpoon select %d', idx) })
    end

    map('n', '<C-j>', function()
      local item = harpoon:list():get(1)
      if item then
        vim.cmd('edit ' .. item.value)
      end
    end, { desc = 'harpoon select 1' })

    map('n', '<C-k>', function()
      local item = harpoon:list():get(2)
      if item then
        vim.cmd('edit ' .. item.value)
      end
    end, { desc = 'harpoon select 2' })

    map('n', '<C-n>', function()
      local item = harpoon:list():get(3)
      if item then
        vim.cmd('edit ' .. item.value)
      end
    end, { desc = 'harpoon select 3' })

    map('n', '<C-p>', function()
      local item = harpoon:list():get(4)
      if item then
        vim.cmd('edit ' .. item.value)
      end
    end, { desc = 'harpoon select 4' })
  end,
}
