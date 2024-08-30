return {
  "nvim-cmp",
  dependencies = {
    "supermaven-inc/supermaven-nvim",
    opts = {},
  },
  opts = function(_, opts)
    table.insert(opts.sources, 1, {
      name = "supermaven",
      group_index = 1,
      priority = 100,
    })
  end,
}
