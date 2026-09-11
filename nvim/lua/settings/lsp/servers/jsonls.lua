-- defaults verified against vscode-langservers-extracted 4.10.0 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-11)
--
-- JSON with the SchemaStore catalogue (package.json, tsconfig.json, nest-cli.json, …).

local M = {}

M.config = {
  filetypes = { "json", "jsonc" },
  init_options = { provideFormatter = false }, -- Prettier formats JSON (task 09)
  settings = {
    json = {
      validate = { enable = true },
      format = { enable = false },
    },
  },
  -- The catalogue is large: resolve it when the server starts, not at startup.
  before_init = function(_, config)
    config.settings.json.schemas = require("schemastore").json.schemas()
  end,
}

return M
