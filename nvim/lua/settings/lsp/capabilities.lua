-- defaults verified against Neovim v0.12.5 (2026-09-11)
--
-- Client capabilities advertised to every language server (settings/lsp/init.lua).

local user = require("user.settings")

local M = {}

---@return lsp.ClientCapabilities
function M.get()
  -- TODO(задача 08): заменить источник на require("blink.cmp").get_lsp_capabilities()
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  return vim.tbl_deep_extend("force", capabilities, {
    workspace = {
      -- Servers (vtsls, eslint) register file watchers dynamically; Neovim keeps
      -- this off by default on Linux. `lsp.disable_watchers` turns it back off
      -- for monorepos where ESLint's watchers eat the CPU.
      didChangeWatchedFiles = { dynamicRegistration = not user.lsp.disable_watchers },
    },
    textDocument = {
      -- Server-side folding ranges (`vim.lsp.foldexpr()`); already Neovim's
      -- defaults, stated explicitly.
      foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
    },
  })
end

return M
