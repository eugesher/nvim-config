-- LSP: server catalogue (nvim-lspconfig), installer (Mason v2 + mason-lspconfig v2),
-- JSON / YAML schemas.

local spec = require("settings").spec

return {
  -- Loads mason first: its PATH entry and `automatic_enable` must be in place
  -- before the first buffer's FileType starts a client.
  spec("neovim/nvim-lspconfig", "lsp", {
    dependencies = { "mason-org/mason.nvim" },
  }),
  spec("mason-org/mason.nvim", "lsp.mason", {
    dependencies = { "mason-org/mason-lspconfig.nvim" },
  }),
  -- Set up from settings/lsp/mason.lua, right after mason itself.
  spec("mason-org/mason-lspconfig.nvim"),
  -- Loaded on require by the jsonls / yamlls configs (task 07).
  spec("b0o/SchemaStore.nvim"),
}
