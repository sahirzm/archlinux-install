require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("v", ">", ">gv", { desc = "indent"})

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")