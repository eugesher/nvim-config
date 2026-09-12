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
  on_init = function(client)
    -- nvim-lspconfig forces formatting on; with `format.enable = false` it would
    -- only offer empty edits.
    client.server_capabilities.documentFormattingProvider = false

    -- Rename is hidden in compose buffers. This server renames YAML anchors, of
    -- which compose files have none, so its `prepareRename` comes back empty —
    -- but `vim.lsp.buf.rename()` walks every client that claims the capability,
    -- so `grn` on a service name ended with a stray "Nothing to rename" after
    -- docker-language-server had already renamed it (task 22).
    -- Capabilities belong to the client, not the buffer, and the same client
    -- serves plain YAML: hence the per-buffer answer here instead of clearing
    -- `renameProvider` outright.
    local supports_method = client.supports_method
    ---@diagnostic disable-next-line: duplicate-set-field
    client.supports_method = function(self, method, bufnr)
      if method == "textDocument/rename" or method == "textDocument/prepareRename" then
        if type(bufnr) == "table" then -- the deprecated `{ bufnr = … }` form
          bufnr = bufnr.bufnr
        end
        local buf = bufnr or vim.api.nvim_get_current_buf()
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "yaml.docker-compose" then
          return false
        end
      end
      return supports_method(self, method, bufnr)
    end
  end,
}

return M
