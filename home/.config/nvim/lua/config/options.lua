-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.g.neovide then
  vim.o.guifont = "FiraCode Nerd Font Mono:h10"
  vim.g.neovide_transparency = 0.95
  vim.g.neovide_cursor_animation_length = 0.06
  vim.g.neovide_scroll_animation_length = 0
end
