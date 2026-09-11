-- User-tunable values: the single place to personalize the editor.
-- Pure data — no `vim.*` calls and no functions, so it is safe to require
-- from anywhere and at any time. New groups (`explorer`, `http`, `database`, …)
-- are added by the tasks that introduce the plugins.

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
  },

  colorscheme = {
    -- Catppuccin flavour: "latte" | "frappe" | "macchiato" | "mocha".
    flavour = "mocha",
    -- Let the terminal background show through the editor surfaces
    -- (replaces `window_bg`).
    transparent = false,
    -- Base background of editor surfaces, side panels, floats and the status line.
    window_bg = "#000000",
  },

  treesitter = {
    -- Buffers above these limits get no treesitter highlighting, indentation or
    -- folds: parsing them stalls the editor (settings/treesitter.lua).
    max_filesize = 1536 * 1024, -- bytes (~1.5 MB)
    max_line_length = 2000, -- characters in the longest line
  },
}
