return {
  'MeanderingProgrammer/render-markdown.nvim',
  lazy = true,
  version = '*',
  config = function()
    require('render-markdown').setup {
      heading = {
        sign = false,
        backgrounds = {
          'RenderMarkdownH2Bg',
          'RenderMarkdownH1Bg',
          'RenderMarkdownH2Bg',
        },
      },
      completions = { blink = { enabled = true } },
      code = {
        enabled = false,
      },
    }
  end,
}
