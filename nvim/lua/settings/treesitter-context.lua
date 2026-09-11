-- defaults verified against nvim-treesitter-context v1.0.0-26-gf306133 (2026-09-11)
--
-- Sticky header: the enclosing function / class stays visible at the top of the
-- window while scrolling through its body (like WebStorm's sticky lines).

local M = {}

M.event = { "BufReadPost", "BufNewFile" }

-- Side panels and auxiliary buffers never get a context window.
local excluded = {
  "neo-tree",
  "trouble",
  "aerial",
  "dbui",
  "dap-view",
  "dap-repl",
  "lazy",
  "mason",
  "help",
  "qf",
  "checkhealth",
}

M.opts = {
  enable = true,
  multiwindow = false, -- only the current window
  max_lines = 3, -- at most three context lines
  min_window_height = 20, -- no context in small splits
  line_numbers = true,
  multiline_threshold = 20, -- lines of a single multi-line context node
  trim_scope = "outer", -- over `max_lines`, drop the outermost scopes first
  mode = "cursor", -- context of the cursor line, not of the top line
  -- `separator` stays unset: catppuccin underlines the last context line instead.
  zindex = 20,
  on_attach = function(buf)
    return not vim.tbl_contains(excluded, vim.bo[buf].filetype)
  end,
}

M.keys = {
  {
    "<leader>uk",
    function()
      require("treesitter-context").toggle()
    end,
    desc = "Toggle sticky context",
  },
}

return M
