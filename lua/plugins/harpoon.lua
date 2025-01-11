return {
  'ThePrimeagen/harpoon',
  branch = 'harpoon2',
  dependencies = { 'nvim-lua/plenary.nvim' },

  config = function()
    local harpoon = require 'harpoon'
    harpoon:setup {}

    vim.keymap.set('n', 'ha', function()
      harpoon:list():add()
    end, { desc = '[H]arpoon [A]dd' })

    vim.keymap.set('n', 'hl', function()
      harpoon.ui:toggle_quick_menu(harpoon:list())
    end, { desc = '[H]arpoon [L]ist' })

    vim.keymap.set('n', 'hn', function()
      harpoon:list():next()
    end, { desc = '[H]arpoon [N]ext' })

    vim.keymap.set('n', 'hp', function()
      harpoon:list():prev()
    end, { desc = '[H]arpoon [P]rev' })

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6, 7 } do
      vim.keymap.set('n', string.format('h%d', idx), function()
        harpoon:list():select(idx)
      end, { desc = string.format('[H]arpoon %d', idx) })
    end
  end,
}
