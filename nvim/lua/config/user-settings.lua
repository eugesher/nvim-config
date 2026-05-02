-- Single source of truth for end-user-tunable values. Edit this file to
-- personalize the editor without diving into individual plugin specs.
--
-- Usage from a plugin spec:
--   local settings = require("config.user-settings")
--   ... settings.neo_tree.window_width_ratio ...
--
-- Conventions:
--   * Group by plugin / subsystem name. Keep keys snake_case.
--   * Values are evaluated once at module-load time and cached by Lua's
--     `package.loaded`. A handful of values (e.g. `neo_tree.window_width`)
--     read from `vim.go.*` to derive a final number — that read happens at
--     load time, so resizing the terminal afterwards does NOT update the
--     value. Keep `vim.*` reads to a minimum and only for cases where the
--     user genuinely wants the derived value, not the formula.
--   * Every value is the SINGLE source of truth — the matching plugin spec
--     reads it via `require("config.user-settings")` and never re-defines it.

return {
  -- Core editor behavior. Fed into nvim's `vim.opt.*` from `config/options.lua`.
  editor = {
    -- Width (in spaces) of one indent step. Drives `tabstop` and `shiftwidth`.
    -- Common values: 2 (Node/TS), 4 (Python/Java).
    indent_width = 2,
  },

  -- Catppuccin colorscheme. Variants (light → dark): latte, frappe, macchiato, mocha.
  colorscheme = {
    flavour = "mocha",
  },

  -- Neo-tree file explorer (lua/plugins/ui.lua).
  neo_tree = {
    -- Sidebar position. One of "left", "right", "top", "bottom", "float", "current".
    position = "left",
    -- Sidebar width in columns. Computed as 25% of the terminal width at the
    -- time this module is first loaded (startup); replace with a literal
    -- integer (e.g. 40) for a fixed width regardless of terminal size.
    window_width = math.floor(vim.go.columns * 0.25),
    -- Hide dotfiles (.gitignore, .env, etc.) by default. Toggle in-tree with `H`.
    hide_dotfiles = true,
    -- Hide files matched by the project's .gitignore. Toggle in-tree with `H`.
    hide_gitignored = true,
  },

  -- conform.nvim format-on-save (lua/plugins/formatting.lua).
  formatting = {
    -- Max wait time for the formatter on save, in milliseconds. Bump on slow
    -- machines or when running prettier with large config files.
    format_on_save_timeout_ms = 3000,
  },

  -- vim-dadbod-ui (lua/plugins/dadbod.lua).
  dadbod = {
    -- Sidebar position. "left" or "right".
    win_position = "left",
    -- Sidebar width in columns.
    winwidth = 35,
  },

  -- kulala.nvim HTTP client (lua/plugins/kulala.lua).
  http = {
    -- Default environment selected at startup. Must match a top-level key in
    -- http/http-client.env.json (e.g. "dev", "staging", "prod").
    default_env = "dev",
  },

  -- bufferline.nvim tab line (lua/plugins/bufferline.lua).
  bufferline = {
    -- LSP diagnostics counts shown next to each buffer's name.
    -- "nvim_lsp" | "coc" | false (disable). Set false to keep the bar quiet.
    diagnostics = "nvim_lsp",
    -- Tab separator style. "slant" | "slope" | "thick" | "thin".
    -- Slant pairs naturally with the rounded edges in catppuccin's palette.
    separator_style = "slant",
    -- Show the bar even with one buffer open (true) vs auto-hide (false).
    always_show = true,
  },

  -- LSP feature toggles (lua/plugins/lsp.lua).
  -- Granular shape: keys mirror the actual LSP server settings so the plugin
  -- spec passes them through with no translation layer. Set any sub-value
  -- to `false` (or its server-defined "off" string) to disable just that hint.
  lsp = {
    -- ts_ls — inline hints rendered next to TypeScript code by the language server.
    ts_inlay_hints = {
      -- Inline names next to function arguments: "all" | "literals" | "none".
      parameter_names = "all",
      -- Inferred types for function parameters that lack an explicit annotation.
      function_parameter_types = true,
      -- Inferred types for `let` / `const` declarations.
      variable_types = true,
    },

    -- eslint server — severity for the `prettier/prettier` rule. Default "off"
    -- because conform.nvim already runs Prettier on save (the ESLint rule
    -- would fire as a duplicate "Delete `␊`" diagnostic). Flip to "warn" or
    -- "error" if you'd rather see the diagnostic instead of the silent fix.
    eslint_prettier_rule_severity = "off",

    -- jsonls — validate JSON against schemas (inline `$schema` and any
    -- schemas registered via SchemaStore). Disable to silence schema errors.
    jsonls_schema_validation = true,
  },
}
