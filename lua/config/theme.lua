local function set_colorscheme_on_enter()
  if vim.o.background == 'light' then
    vim.cmd.colorscheme 'catppuccin-latte'
  else
    vim.cmd.colorscheme 'kanagawa-wave'
    -- vim.cmd.colorscheme 'rose-pine'
  end
end

set_colorscheme_on_enter()
