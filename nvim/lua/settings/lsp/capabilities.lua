local user = require("user.settings")

local M = {}

function M.get()
  local extra = {
    workspace = {
      didChangeWatchedFiles = { dynamicRegistration = not user.lsp.disable_watchers },
    },
    textDocument = {
      foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
    },
  }

  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    return blink.get_lsp_capabilities(extra, true)
  end
  return vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), extra)
end

return M
