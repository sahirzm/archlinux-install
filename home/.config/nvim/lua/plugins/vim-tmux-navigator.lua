-- smart-splits moves between Neovim splits and hands off to the multiplexer
-- (zellij, tmux or WezTerm) at the edge. In zellij, vim-zellij-navigator
-- (~/.config/zellij/config.kdl) passes Ctrl-h/j/k/l through to nvim. Load
-- eagerly so WezTerm's IS_NVIM user variable is set before the first keypress.
return {
  { "christoomey/vim-tmux-navigator", enabled = false },
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = {},
    keys = {
      { "<c-h>", function() require("smart-splits").move_cursor_left() end, desc = "Navigate left" },
      { "<c-j>", function() require("smart-splits").move_cursor_down() end, desc = "Navigate down" },
      { "<c-k>", function() require("smart-splits").move_cursor_up() end, desc = "Navigate up" },
      { "<c-l>", function() require("smart-splits").move_cursor_right() end, desc = "Navigate right" },
      { "<c-\\>", function() require("smart-splits").move_cursor_previous() end, desc = "Navigate previous" },
    },
  },
}
