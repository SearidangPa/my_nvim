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

    vim.keymap.set("n", "<C-S-P>", function() harpoon:list():prev() end)
    vim.keymap.set("n", "<C-S-N>", function() harpoon:list():next() end)

    harpoon:extend {
      UI_CREATE = function(cx)
        vim.keymap.set('n', '<C-v>', function()
          harpoon.ui:select_menu_item { vsplit = true }
        end, { buffer = cx.bufnr })
      end,
    }

    for _, idx in ipairs { 1, 2, 3, 4, 5, 6, 7 } do
      vim.keymap.set('n', string.format('<localleader>%d', idx), function()
        harpoon:list():select(idx)
      end, { desc = string.format('harpoon %d', idx) })
    end
  end,
}
