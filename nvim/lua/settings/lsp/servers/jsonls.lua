local M = {}

M.config = {
  filetypes = { "json", "jsonc" },
  init_options = { provideFormatter = false },
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
