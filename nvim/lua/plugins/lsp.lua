local spec = require("settings").spec

return {
  spec("neovim/nvim-lspconfig", "lsp.lspconfig", {
    dependencies = { "mason-org/mason.nvim", "b0o/SchemaStore.nvim" },
  }),
  spec("mason-org/mason.nvim", "lsp.mason", {
    dependencies = { "mason-org/mason-lspconfig.nvim" },
  }),
  spec("mason-org/mason-lspconfig.nvim"),
  spec("b0o/SchemaStore.nvim"),
}
