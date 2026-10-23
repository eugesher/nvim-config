local schemas = require("settings.lsp.schemas")

local M = {}

M.config = {
  filetypes = { "json", "jsonc" },
  init_options = { provideFormatter = false, handledSchemaProtocols = { "file" } },
  handlers = { ["vscode/content"] = schemas.content },
  settings = {
    json = {
      validate = { enable = true },
      format = { enable = false },
    },
  },
  before_init = function(_, config)
    config.settings.json.schemas = require("schemastore").json.schemas()
  end,
}

return M
