-- defaults verified against vscode-langservers-extracted 4.10.0 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-11)
--
-- ESLint diagnostics and fixes. `:LspEslintFixAll` (nvim-lspconfig) and the
-- "Fix all" code action on `<leader>ca` / `gra` stay available; nothing is
-- fixed automatically.
--
-- Root: nvim-lspconfig's `root_dir` is kept. It looks for exactly these configs
-- (eslint.config.js / .mjs / .cjs / .ts, .eslintrc*, `eslintConfig` in
-- package.json) and does not start ESLint in projects without one — a
-- `root_markers` list would be ignored next to it anyway.

local M = {}

M.config = {
  -- vue / svelte / astro from nvim-lspconfig's list are not in this stack.
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  settings = {
    -- The server's own key (VSCode's `eslint.workingDirectories` is a client-side
    -- setting translated into this one). "auto": nearest package.json / config.
    workingDirectory = { mode = "auto" }, -- monorepos
    format = false, -- Prettier formats through conform
    useFlatConfig = true, -- ESLint 9+ (`experimental.useFlatConfig` is deprecated)
    codeActionOnSave = { enable = false, mode = "all" }, -- no auto-fix on save, on purpose
    -- Prettier already runs on save; the rule would only duplicate it as an
    -- endless "Delete `␊`" diagnostic, so it is silenced at the server.
    rulesCustomizations = { { rule = "prettier/prettier", severity = "off" } },
    run = "onType",
    problems = { shortenToSingleLine = false },
  },
}

return M
