-- defaults verified against bash-language-server 5.6.0 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-11)
--
-- Shell scripts (install.sh, CI helpers). ShellCheck diagnostics appear when
-- `shellcheck` is on $PATH.

local M = {}

M.config = {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash" },
  settings = {
    bashIde = {
      globPattern = "**/*@(.sh|.inc|.bash|.command)", -- files indexed for workspace symbols
    },
  },
}

return M
