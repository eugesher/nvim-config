local M = {}

M.config = {
  filetypes = { "yaml", "yaml.docker-compose" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = {
      schemaStore = { enable = false, url = "" },
      validate = true,
      hover = true,
      completion = true,
      format = { enable = false },
      keyOrdering = false,
    },
  },
  before_init = function(_, config)
    config.settings.yaml.schemas = require("schemastore").yaml.schemas()
  end,
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false

    local supports_method = client.supports_method
    ---@diagnostic disable-next-line: duplicate-set-field
    client.supports_method = function(self, method, bufnr)
      if method == "textDocument/rename" or method == "textDocument/prepareRename" then
        if type(bufnr) == "table" then
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
