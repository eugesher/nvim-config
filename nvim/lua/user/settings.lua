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
    title = "Neovim: %{fnamemodify(getcwd(), ':t')}",
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
    timeout_ms = 5000,
    max_filesize = 4 * 1024 * 1024,
    sql_dialect = "mysql",
  },

  explorer = {
    position = "left",
    width = 48,
    min_width = 40,
    hide_gitignored = true,
    group_empty_dirs = false,
  },

  git = {
    lazygit_scale = 1,
  },

  finder = {
    fullscreen = true,
  },

  http = {
    default_env = "dev",
    kulala_core_sha256 = "750a79cf888b30801225b3b9af644447be9e9fe3a55bfa8c0b1daabe54474502",
  },

  completion = {
    fuzzy_sha256 = "1b09e702955be4e2565206d8649db674ccb77477495ed787868f451bf33cea2f",
  },

  trust = {
    git_timeout_ms = 2000,
  },

  mason = {
    registry = "2026-10-14-frank-knight",
    servers = {
      vtsls = "0.3.0",
      eslint = "4.10.0",
      lua_ls = "3.19.1",
      jsonls = "4.10.0",
      yamlls = "1.24.0",
      bashls = "5.6.0",
      codebook = "v0.3.42",
      docker_language_server = "v0.20.1",
      dockerls = "0.15.0",
    },
    tools = {
      prettierd = "0.29.0",
      prettier = "3.9.6",
      stylua = "v2.5.2",
      ["js-debug-adapter"] = "v1.117.0",
      ["sql-formatter"] = "15.8.2",
    },
  },

  spelling = {
    project_dictionary = ".codebook/words.toml",
    check_paths = true,
    scan_timeout = 5000,
    scan_parallel = 8,
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
    import_style = "shortest",
    unused_symbols = true,
    unused_skip = {
      paths = { "**/node_modules/**" },
      fields = { "*" },
      methods = { "*.controller.ts" },
    },
    diagnostics_summary = {
      width = 100,
      sources = {
        Codebook = {
          label = "Possible spelling issues",
          hint = "<leader>cw adds all of them to the dictionary",
        },
      },
    },
  },
}
