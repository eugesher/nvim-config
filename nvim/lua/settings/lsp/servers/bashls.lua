local M = {}

M.config = {
  cmd = { "bash-language-server", "start" },
  filetypes = { "sh", "bash" },
  settings = {
    bashIde = {
      globPattern = "**/*@(.sh|.inc|.bash|.command)",
    },
  },
}

return M
