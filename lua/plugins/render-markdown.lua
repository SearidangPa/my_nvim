return {
  'MeanderingProgrammer/render-markdown.nvim',
  lazy = true,
  ft = { 'markdown' },
  version = '*',
  opts = {
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
  },
}
