return {
  'jake-stewart/multicursor.nvim',
  branch = '1.0',
  config = function()
    local mc = require 'multicursor-nvim'
    mc.setup()
    local set = vim.keymap.set

    set({ 'n', 'v' }, '<up>', function()
      mc.lineAddCursor(-1)
    end, { noremap = true, desc = 'Add cursor above' })

    set({ 'n', 'v' }, '<down>', function()
      mc.lineAddCursor(1)
    end, { noremap = true, desc = 'Add cursor below' })

    set({ 'n', 'v' }, '<leader><up>', function()
      mc.lineSkipCursor(-1)
    end, { noremap = true, desc = 'Skip cursor above' })

    set({ 'n', 'v' }, '<leader><down>', function()
      mc.lineSkipCursor(1)
    end, { noremap = true, desc = 'Skip cursor below' })

    set({ 'n', 'v' }, '<leader>x', mc.deleteCursor, { noremap = true, desc = 'Delete cursor' })
    set('n', '<c-leftmouse>', mc.handleMouse, { noremap = true, desc = 'Add cursor with control + left click' })
    set({ 'n', 'v' }, '<c-q>', mc.toggleCursor, { noremap = true, desc = 'Toggle cursor' })
    set('v', 'I', mc.insertVisual, { noremap = true, desc = 'Insert for each line of the visual section' })
    set('v', 'A', mc.appendVisual, { noremap = true, desc = 'Append for each line of the visual section' })
    set('v', 'M', mc.matchCursors, { noremap = true, desc = 'Match cursors within visual selection by regex' })

    set('n', '<esc>', function()
      if not mc.cursorsEnabled() then
        mc.enableCursors()
      elseif mc.hasCursors() then
        mc.clearCursors()
      else
      end
    end)

    -- Customize how cursors look.
    local hl = vim.api.nvim_set_hl
    hl(0, 'MultiCursorCursor', { link = 'Cursor' })
    hl(0, 'MultiCursorVisual', { link = 'Visual' })
    hl(0, 'MultiCursorSign', { link = 'SignColumn' })
    hl(0, 'MultiCursorDisabledCursor', { link = 'Visual' })
    hl(0, 'MultiCursorDisabledVisual', { link = 'Visual' })
    hl(0, 'MultiCursorDisabledSign', { link = 'SignColumn' })
  end,
}
