return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },

  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}

    vim.keymap.set('n', '<leader>a', function()
      harpoon:list():add()
    end, { desc = 'add to harpoon' })

    vim.keymap.set('n', '<leader>l', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'Harpoon (Default)' })

    vim.keymap.set('n', '<C-]>', function()
      harpoon:list():next()
    end, { desc = 'Harpoon next' })

    vim.keymap.set('n', '<C-[>', function()
      harpoon:list():prev()
    end, { desc = 'Harpoon prev' })

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6, 7 } do
      vim.keymap.set('n', string.format('<leader>%d', idx), function()
        harpoon:list():select(idx)
      end, { desc = string.format('harpoon %d', idx) })
    end
  end,
}
