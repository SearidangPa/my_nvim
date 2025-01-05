local function set_colorscheme_on_enter()
  if vim.o.background == 'light' then
    vim.cmd.colorscheme 'github_light'
  else
    vim.cmd.colorscheme 'kanagawa-wave'
  end
end

set_colorscheme_on_enter()
