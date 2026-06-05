return {
  "mfussenegger/nvim-jdtls",
  opts = {
    root_dir = function(fname)
      return vim.fs.root(fname, { "packageInfo", "Config", "build.gradle", "build.gradle.kts", "pom.xml", "settings.gradle", ".git" })
    end,
  },
}
