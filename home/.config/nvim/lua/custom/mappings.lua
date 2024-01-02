---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },
    ["<C-h>"] = { "<cmd> TmuxNavigateLeft<cr>", "window left" },
    ["<C-j>"] = { "<cmd> TmuxNavigateDown<cr>", "window down"},
    ["<C-k>"] = { "<cmd> TmuxNavigateUp<cr>", "window up" },
    ["<C-l>"] = { "<cmd> TmuxNavigateRight<cr>", "window right" },
    ["<C-\\>"] = { "<cmd> TmuxNavigatePrevious<cr>", "previous window" },
  },
  v = {
    [">"] = { ">gv", "indent"},
  },
}

-- more keybinds!

return M
