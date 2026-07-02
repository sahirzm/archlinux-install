return {
  {
    "mfussenegger/nvim-jdtls",
    opts = {
      root_dir = function(fname)
        return vim.fs.root(fname, { "packageInfo", "Config", "build.gradle", "build.gradle.kts", "pom.xml", "settings.gradle", ".git" })
      end,
    },
  },
  -- The LazyVim scala extra attaches nvim-metals to java files, which conflicts
  -- with nvim-jdtls and prompts to install Metals when opening any .java file.
  {
    "scalameta/nvim-metals",
    ft = function()
      return { "scala", "sbt" }
    end,
    config = function(self, metals_config)
      local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "scala", "sbt" },
        callback = function()
          require("metals").initialize_or_attach(metals_config)
        end,
        group = nvim_metals_group,
      })
    end,
  },
}
