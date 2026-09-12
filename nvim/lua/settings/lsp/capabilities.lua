-- defaults verified against Neovim v0.12.5 and blink.cmp v1.10.2 (2026-09-11)
--
-- Client capabilities advertised to every language server (settings/lsp/lspconfig.lua):
-- Neovim's defaults, blink.cmp's completion capabilities on top, then ours.

local user = require("user.settings")

local M = {}

---@return lsp.ClientCapabilities
function M.get()
  local extra = {
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
  }

  -- blink.cmp merges Neovim's defaults < its completion capabilities < `extra`.
  -- Only our additions go in as the override: passing Neovim's full defaults
  -- there would overwrite blink's completion capabilities with the narrower ones.
  -- Guarded, so a missing blink.cmp never takes LSP down with it.
  local ok, blink = pcall(require, "blink.cmp")
  if ok then
    return blink.get_lsp_capabilities(extra, true)
  end
  return vim.tbl_deep_extend("force", vim.lsp.protocol.make_client_capabilities(), extra)
end

return M
