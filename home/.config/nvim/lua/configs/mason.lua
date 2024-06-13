local opts  = {
  ensure_installed = {
    -- lsp
    "awk-language-server",
    "bash-language-server",
    "clangd",
    "css-lsp",
    "deno",
    "docker-compose-language-service",
    "dockerfile-language-server",
    "gradle-language-server",
    "html-lsp",
    "lua-language-server",
    "jdtls",
    "json-lsp",
    "kotlin-language-server",
    "nginx-language-server",
    "rust-analyzer",
    "sqlls",
    "typescript-language-server",
    "tailwindcss-language-server",
    "yaml-language-server",
    -- formatter
    "clang-format",
    "google-java-format",
    "prettier",
    "stylua",
    -- linter
    "checkstyle",
    "editorconfig-checker",
    "jsonlint",
    "ktlint",
    "typos",
    -- dap
    "java-debug-adapter",
    "java-test",
    "kotlin-debug-adapter",
    "vscode-java-decompiler",
  },
}

return opts;
