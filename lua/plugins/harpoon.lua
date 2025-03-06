return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },

  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}

    vim.keymap.set('n', '<localleader>a', function()
      harpoon:list():add()
    end, { desc = 'harpoon [A]dd' })

    vim.keymap.set('n', '<localleader>p', function()
      harpoon:list():prepend()
    end, { desc = 'harpoon [P]repend' })

    vim.keymap.set('n', '<localleader>l', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = 'harpoon [L]ist' })

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6, 7 } do
      vim.keymap.set('n', string.format('<localleader>%d', idx), function()
        harpoon:list():select(idx)
      end, { desc = string.format('harpoon %d', idx) })
    end
  end,
}
