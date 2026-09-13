-- User-tunable values: the single place to personalize the editor.
-- Pure data — no `vim.*` calls and no functions, so it is safe to require
-- from anywhere and at any time.

return {
  editor = {
    -- Width of one indent step: drives 'shiftwidth', 'tabstop', 'softtabstop'.
    indent_width = 2,
    -- Minimal number of lines kept above/below the cursor.
    scrolloff = 8,
    -- Relative line numbers (the current line still shows its absolute number).
    relative_number = true,
  },

  ui = {
    -- Border style for floating windows: "none" | "single" | "double" |
    -- "rounded" | "solid" | "shadow" | "bold". Feeds 'winborder'.
    border = "rounded",
    -- Height of the bottom panels, in lines. One value for all of them —
    -- the debugger panel (dap-view), the test output and the problems list
    -- share the same split, and different heights make them jump.
    panel_height = 12,
    -- The terminal uses a Nerd Font (v3): icons everywhere assume one. Neovim
    -- cannot see the terminal's font, so `:checkhealth myconfig` only trusts
    -- this flag — set it to false on a machine without such a font.
    nerd_font = true,
  },

  colorscheme = {
    -- Catppuccin together with every color tweak of this config (backgrounds,
    -- borders, status line, tabs, sign colors). false: Neovim's default
    -- colorscheme and each plugin's own colors; the values below are then ignored.
    enabled = true,
    -- Catppuccin flavor: "latte" | "frappe" | "macchiato" | "mocha".
    flavour = "mocha",
    -- Let the terminal background show through the editor surfaces
    -- (replaces `window_bg`).
    transparent = false,
    -- Base background of editor surfaces, side panels, floats and the status line.
    window_bg = "#000000",
  },

  treesitter = {
    -- Buffers above these limits get no treesitter highlighting, indentation or
    -- folds: parsing them stalls the editor (settings/treesitter/treesitter.lua).
    max_filesize = 1536 * 1024, -- bytes (~1.5 MB)
    max_line_length = 2000, -- characters in the longest line
  },

  formatting = {
    -- Format on save (conform.nvim). Toggle with <leader>uf (buffer) / <leader>uF
    -- (global) or :FormatDisable[!] / :FormatEnable[!].
    format_on_save = true,
    -- Milliseconds a formatter may block the save.
    timeout_ms = 3000,
    -- Larger files (bytes) are saved as they are, without formatting.
    max_filesize = 1024 * 1024,
  },

  explorer = {
    -- Side of the neo-tree panel: "left" | "right".
    position = "left",
    -- Panel width: a number of columns, or a share of the editor width as a
    -- percentage string ("25%"), taken each time the panel opens.
    width = "25%",
    -- Columns the panel never goes below, whatever `width` gives.
    min_width = 36,
    -- Hide files matched by .gitignore (`H` in the tree shows them anyway).
    hide_gitignored = true,
  },

  http = {
    -- Environment selected in .http buffers on startup; the keys come from
    -- http/http-client.env.json (`<leader>he` switches).
    default_env = "dev",
  },

  coverage = {
    -- Command that produces coverage/lcov.info, run by :CoverageRun; the report
    -- is loaded as soon as it finishes. NestJS projects ship a `test:cov` script.
    command = { "npm", "run", "test:cov" },
  },

  database = {
    -- Side of the vim-dadbod-ui drawer: "left" | "right".
    position = "left",
    -- Drawer width in columns.
    width = 40,
  },

  lsp = {
    -- Inlay hints (parameter names, inferred types) shown as soon as a server
    -- that supports them attaches. false: off until `<leader>ui` turns them on
    -- in a buffer.
    inlay_hints = false,
    -- Stop advertising file watching (workspace/didChangeWatchedFiles). Cuts the
    -- CPU load of ESLint / TS servers in large monorepos, at the price of not
    -- noticing files changed outside the editor.
    disable_watchers = false,
  },
}
