return {
  "nvim-treesitter/nvim-treesitter",
  optional = true,
  opts = {
    ensure_installed = {
      "bash",
      "c",
      "cpp",
      "css",
      "html",
      "javascript",
      "json",
      "lua",
      "markdown",
      "python",
      "query",
      "regex",
      "rust",
      "scss",
      "sql",
      "toml",
      "typescript",
      "yaml",
    },
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },
  },
}
