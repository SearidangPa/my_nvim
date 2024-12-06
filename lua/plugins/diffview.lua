return {
  'sindrets/diffview.nvim',
  config = function()
    require('diffview').setup {
      view = {
        default = {
          layout = 'diff2_horizontal',
        },
        merge_tool = {
          layout = 'diff3_mixed',
        },
      },
    }
  end,
}
