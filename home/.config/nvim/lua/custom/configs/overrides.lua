local M = {}

M.treesitter = {
  ensure_installed = {
    "vim",
    "lua",
    "html",
    "css",
    "javascript",
    "typescript",
    "tsx",
    "c",
    "markdown",
    "markdown_inline",
    "bash",
    "json",
    "toml",
    "yaml",
    "angular",
    "awk",
    "cmake",
    "comment",
    "csv",
    "dart",
    "dockerfile",
    "git_config",
    "git_rebase",
    "gitattributes",
    "gitcommit",
    "gitignore",
    "go",
    "graphql",
    "kotlin",
    "make",
    "python",
    "java",
    "ruby",
    "rust",
    "scala",
    "sql",
    "tsv",
    "xml",
  },
  indent = {
    enable = true,
    -- disable = {
    --   "python"
    -- },
  },
}

M.mason = {
  ensure_installed = {
    -- lua stuff
    "lua-language-server",
    "stylua",

    -- web dev stuff
    "css-lsp",
    "html-lsp",
    "typescript-language-server",
    "deno",
    "prettier",
    "tailwindcss-language-server",

    -- c/cpp stuff
    "clangd",
    "clang-format",
    "awk-language-server",
    "bash-language-server",
    "checkstyle",
    "dockerfile-langugage-server",
    "editorconfig-checker",
    "google-java-format",
    "gradle-langugage-server",
    "java-debug-adapter",
    "java-test",
    "jdtls",
    "json-lsp",
    "jsonlint",
    "kotlin-debug-adapter",
    "kotlin-language-server",
    "ktlint",
    "nginx-language-server",
    "rust-analyzer",
    "sqlls",
    "typos",
    "vscode-java-decompiler",
    "yaml-langugage-server",
  },
}

-- git support in nvimtree
M.nvimtree = {
  git = {
    enable = true,
  },

  renderer = {
    highlight_git = true,
    icons = {
      show = {
        git = true,
      },
    },
  },
}

return M
