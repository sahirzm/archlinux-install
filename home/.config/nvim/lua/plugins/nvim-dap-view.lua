return {
  {
    "igorlfs/nvim-dap-view",
    ---@module 'dap-view'
    ---@type dapview.Config
    keys = {
      { "<leader>du", function() require("dap-view").toggle() end, desc = "Dap UI" }
    },
    opts = {
      winbar = {
        sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
        default_section = "threads",
        controls = {
          enabled = true,
        },
      },
      auto_toggle = true
    },
  },
}
