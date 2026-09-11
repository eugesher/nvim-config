-- User-tunable values: the single place to personalize the editor.
-- Pure data — no `vim.*` calls and no functions, so it is safe to require
-- from anywhere and at any time. New groups (`colorscheme`, `explorer`,
-- `http`, `database`, …) are added by the tasks that introduce the plugins.

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
    -- Transparent background (consumed by the colorscheme, task 03).
    transparent = false,
  },
}
