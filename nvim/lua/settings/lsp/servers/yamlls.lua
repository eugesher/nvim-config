-- defaults verified against yaml-language-server 1.24.0 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-11)
--
-- YAML with the SchemaStore catalogue (GitHub workflows, docker-compose, …).

local M = {}

M.config = {
  -- nvim-lspconfig also lists `yaml.gitlab` / `yaml.helm-values`: filetypes
  -- Neovim never produces, which `:checkhealth vim.lsp` reports as unknown.
  -- `yaml.docker-compose` stays: core/filetypes.lua gives it to compose files,
  -- and this server is the only one that validates them against the Compose
  -- Specification schema — docker-language-server reports YAML syntax errors
  -- and nothing else there (measured in task 22).
  filetypes = { "yaml", "yaml.docker-compose" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemaStore = { enable = false, url = "" }, -- the catalogue comes from SchemaStore.nvim
      validate = true,
      hover = true,
      completion = true,
      format = { enable = false }, -- Prettier formats YAML (task 09)
      keyOrdering = false, -- otherwise every mapping must be sorted alphabetically
    },
  },
  -- The catalogue is large: resolve it when the server starts, not at startup.
  before_init = function(_, config)
    config.settings.yaml.schemas = require("schemastore").yaml.schemas()
  end,
  -- nvim-lspconfig forces formatting on; with `format.enable = false` it would
  -- only offer empty edits.
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
  end,
}

return M
