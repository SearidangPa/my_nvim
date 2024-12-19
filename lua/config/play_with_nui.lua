local nui_input = require 'nui.input'
local event = require('nui.utils.autocmd').event

local width = math.floor(vim.o.columns * 0.9)
local height = math.floor(vim.o.lines * 0.25)
local row = math.floor((vim.o.columns - width))
local col = math.floor((vim.o.lines - height))

local input = nui_input({
  position = { row = row, col = col },
  size = {
    width = 120,
  },
  border = {
    style = 'rounded',
    text = {
      top = '[Howdy?]',
      top_align = 'center',
    },
  },
  win_options = {
    winhighlight = 'Normal:Normal,FloatBorder:Normal',
  },
}, {
  prompt = '> ',
  default_value = 'Hello',
  on_close = function()
    print 'Input Closed!'
  end,
  on_submit = function(value)
    print('Input Submitted: ' .. value)
  end,
})

-- mount/open the component
input:mount()

-- unmount component when cursor leaves buffer
input:on(event.BufLeave, function()
  input:unmount()
end)
