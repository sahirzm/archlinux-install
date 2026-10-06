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
vim.opt.clipboard = { "unnamed", "unnamedplus" }

-- Without a display (SSH, cloud desktop), copy through OSC 52 so yanks reach the
-- laptop's clipboard via zellij and kitty. Paste reads nvim's own register:
-- reading the clipboard over OSC 52 is blocked by zellij and prompts in kitty.
if not (vim.env.WAYLAND_DISPLAY or vim.env.DISPLAY) or vim.env.SSH_CONNECTION then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end
