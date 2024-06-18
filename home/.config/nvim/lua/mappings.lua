require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("v", ">", ">gv", { desc = "indent"})

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- keybindings for motion - leap.nvim
map({"n", "x", "o"}, "s", "<Plug>(leap-forward)")
map({"n", "x", "o"}, "S", "<Plug>(leap-backward)")

-- ranger
map("n", "<leader>ef", "", {
  noremap = true,
  callback = function()
    require("ranger-nvim").open(true)
  end,
})
