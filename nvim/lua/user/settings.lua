return {
  editor = {
    indent_width = 2,
    scrolloff = 8,
    relative_number = false,
    readonly_dirs = { "node_modules" },
  },

  ui = {
    border = "rounded",
    panel_height = 12,
    nerd_font = true,
  },

  colorscheme = {
    enabled = true,
    flavour = "mocha",
    transparent = true,
    transparent_floats = true,
    window_bg = "#000000",
  },

  treesitter = {
    max_filesize = 1536 * 1024,
    max_line_length = 2000,
  },

  folding = {
    auto_fold_kinds = { "comment" },
  },

  formatting = {
    format_on_save = true,
    timeout_ms = 3000,
    max_filesize = 1024 * 1024,
    sql_dialect = "mysql",
  },

  explorer = {
    position = "left",
    width = 48,
    min_width = 40,
    hide_gitignored = true,
    group_empty_dirs = false,
  },

  http = {
    default_env = "dev",
  },

  coverage = {
    command = { "npm", "run", "test:cov" },
  },

  database = {
    position = "left",
    width = 40,
  },

  lsp = {
    inlay_hints = false,
    disable_watchers = false,
  },
}
