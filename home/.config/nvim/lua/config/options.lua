-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.g.neovide then
  vim.o.guifont = "FiraCode Nerd Font Mono:h12"
  vim.g.neovide_opacity = 0.95
  vim.g.neovide_cursor_animation_length = 0.06
  vim.g.neovide_scroll_animation_length = 0
end

-- Enable this option to avoid conflicts with Prettier.
vim.g.lazyvim_prettier_needs_config = true
