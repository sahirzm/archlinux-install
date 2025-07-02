return {
  "nvim-neorg/neorg",
  dependencies = { "luarocks.nvim" },
  lazy = false, -- Disable lazy loading as some `lazy.nvim` distributions set `lazy = true` by default
  version = "*", -- Pin Neorg to the latest stable release
  config = function()
    require("neorg").setup({
      load = {
        ["core.defaults"] = {},
        ["core.concealer"] = {},
        ["core.completion"] = {
          config = {
            engine = "nvim-cmp",
            sources = {
              { name = "words" },
              { name = "snippets" },
              { name = "emoji" },
            },
          },
        },
        ["core.presenter"] = { config = { zen_mode = "zen-mode" } },
        ["core.export"] = {},
        ["core.export.markdown"] = { config = { extensions = "all" } },
        ["core.summary"] = {},
        ["core.tangle"] = {},
        ["core.looking-glass"] = {},
        ["core.qol.toc"] = {},
        ["core.qol.todo_items"] = {},
        ["core.dirman"] = {
          config = {
            workspaces = {
              work = "~/notes/work",
              notes = "~/notes/notes",
            },
            default_workspace = "notes",
          },
        },
      },
    })
  end,
}
