local M = {}

M.config = {
  cmd = { "codebook-lsp", "serve" },
  filetypes = {
    "typescript",
    "typescriptreact",
    "javascript",
    "javascriptreact",
    "lua",
    "markdown",
    "json",
    "jsonc",
    "yaml",
    "html",
    "css",
    "sql",
    "http",
    "gitcommit",
  },
  root_markers = { "codebook.toml", ".codebook.toml", ".git" },
  exit_timeout = 500,
  init_options = {
    logLevel = "info",
    checkWhileTyping = true,
    diagnosticSeverity = "hint",
  },
}

local enabled = true

function M.toggle()
  enabled = not enabled
  vim.lsp.enable("codebook", enabled)
  vim.notify("codebook: spelling " .. (enabled and "enabled" or "disabled"))
end

return M
