return {
  'sindrets/diffview.nvim',
  config = function()
    local actions = require 'diffview.actions'

    require('diffview').setup {
      view = {
        default = {
          layout = 'diff2_horizontal',
        },
        merge_tool = {
          layout = 'diff1_plain',
        },
      },
      keymaps = {
        view = {
          { 'n', '<M-o>', actions.conflict_choose 'ours', { desc = 'Choose the OURS version of a conflict' } },
          { 'n', '<M-t>', actions.conflict_choose 'theirs', { desc = 'Choose the THEIRS version of a conflict' } },

          { 'n', '<M-O>', actions.conflict_choose_all 'ours', {
            desc = 'Choose the OURS version of a conflict for the whole file',
          } },
          {
            'n',
            '<M-T>',
            actions.conflict_choose_all 'theirs',
            {
              desc = 'Choose the THEIRS version of a conflict for the whole file',
            },
          },
        },
      },
    }
  end,
}
