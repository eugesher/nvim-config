-- defaults verified against codebook-lsp 0.3.42 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-12)
--
-- Spell checking for code. codebook is a language server (Rust + tree-sitter +
-- Spellbook), not a plugin: it splits camelCase / PascalCase / snake_case /
-- SCREAMING_SNAKE_CASE itself, suggests fixes in the original case, and tells
-- identifiers, strings and comments apart — so the hand-written "definitions
-- only" filter of the old config is gone and is not coming back.
-- cspell.nvim (archived) and cspell-lsp (deprecated) are not part of this config.
--
-- Dictionaries live outside ~/.config/nvim, which install.sh overwrites whole:
-- the global one in ~/.config/codebook/codebook.toml, the project one in
-- codebook.toml next to .git. `<leader>ca` offers "Add to dictionary" wherever
-- a word is flagged.

local M = {}

M.config = {
  cmd = { "codebook-lsp", "serve" },
  -- The filetypes of this stack, not the language list of the server: TS/JS
  -- sources, configs and documents. `http` and `sql` are ours (tasks 14, 15).
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
  -- A project config wins over the global one; `.git` keeps the server rooted
  -- at the repository even when the project has no codebook.toml of its own.
  root_markers = { "codebook.toml", ".codebook.toml", ".git" },
  -- Neovim's default is `false`: never force-stop, just ask and wait. codebook
  -- does not exit on its own, so without this the client stays registered (and
  -- its diagnostics on screen) after `<leader>us` — see M.toggle below.
  exit_timeout = 500,
  init_options = {
    logLevel = "info",
    checkWhileTyping = true,
    -- Spelling is not an error. HINT keeps it out of the error and warning
    -- counters of the status line and the buffer tabs (task 03) and sorts it
    -- below real problems in the panel (task 20). Done on the server, not by
    -- rewriting diagnostics afterwards: one option instead of a handler that
    -- would have to cover both push and pull diagnostics. The server's own
    -- default is "information".
    diagnosticSeverity = "hint",
  },
}

-- `<leader>us` (settings/lsp/init.lua). Stops the server instead of hiding its
-- diagnostics: a disabled diagnostic namespace still shows up in
-- `vim.diagnostic.get()` and `vim.diagnostic.count()`, so the status line and
-- the problems list would keep counting spelling items that are no longer drawn
-- anywhere (checked against Neovim 0.12.5). Stopping the client clears them
-- everywhere; switching back on re-attaches to the open buffers.
local enabled = true -- settings/lsp/init.lua enables codebook at startup

function M.toggle()
  enabled = not enabled
  vim.lsp.enable("codebook", enabled)
  vim.notify("codebook: spelling " .. (enabled and "enabled" or "disabled"))
end

return M
