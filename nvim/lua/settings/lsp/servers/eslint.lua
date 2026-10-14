local M = {}

M.config = {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  settings = {
    workingDirectory = { mode = "auto" },
    format = false,
    useFlatConfig = true,
    codeActionOnSave = { enable = false, mode = "all" },
    rulesCustomizations = { { rule = "prettier/prettier", severity = "off" } },
    run = "onType",
    problems = { shortenToSingleLine = false },
  },
}

return M
