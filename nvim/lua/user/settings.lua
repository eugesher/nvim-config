return {
  editor = {
    indent_width = 2,
    scrolloff = 8,
    relative_number = false,
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

  formatting = {
    format_on_save = true,
    timeout_ms = 3000,
    max_filesize = 1024 * 1024,
  },

  explorer = {
    position = "left",
    width = "20%",
    min_width = 36,
    hide_gitignored = true,
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
