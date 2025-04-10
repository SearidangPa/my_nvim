return {
  'j-hui/fidget.nvim', -- fidget.nvim dependency remains
  config = function()
    -- Configure fidget.nvim to show LSP progress (the “LSP sign of life”)
    require('fidget').setup {
      text = {
        spinner = 'dots', -- Choose your preferred spinner; "dots" is one example
        done = '✔', -- Symbol to display when the task is done
      },
      window = {
        -- Optionally customize the window’s appearance/position if needed.
        relative = 'editor',
        blend = 10, -- Semi-transparency example
      },
      align = {
        bottom = true, -- Align at the bottom (adjust as you see fit)
        right = true, -- Align to the right side
      },
      -- Additional configuration parameters can be added here.
    }
  end,
}
