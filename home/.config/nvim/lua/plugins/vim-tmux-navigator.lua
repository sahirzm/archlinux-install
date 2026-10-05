-- smart-splits supports both WezTerm and tmux. Load eagerly so its IS_NVIM
-- user variable is set before the terminal handles the first Ctrl-h/j/k/l.
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
