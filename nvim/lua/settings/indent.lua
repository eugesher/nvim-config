-- defaults verified against indent-blankline.nvim v3.10.1 (2026-09-11)
--
-- Indent guides with the current scope highlighted. Scope needs a treesitter
-- parser: the bundled ones work now, the rest arrive in task 05.

local M = {}

M.event = { "BufReadPost", "BufNewFile" }

M.opts = {
  enabled = true,
  debounce = 200, -- ms between refreshes
  viewport_buffer = { min = 30 }, -- lines beyond the viewport; `max` is deprecated
  indent = {
    char = "│",
    tab_char = "»", -- tabs stand out, same glyph as 'listchars'
    highlight = "IblIndent",
    smart_indent_cap = true,
    priority = 1,
    repeat_linebreak = true,
  },
  whitespace = {
    highlight = "IblWhitespace",
    remove_blankline_trail = true,
  },
  scope = {
    enabled = true,
    char = "│",
    show_start = false, -- no underline on the scope's first line
    show_end = false,
    show_exact_scope = false,
    injected_languages = true,
    highlight = "IblScope",
    priority = 1024,
    include = { node_type = {} },
    exclude = {
      language = {},
      node_type = {
        ["*"] = { "source_file", "program" },
        lua = { "chunk" },
        python = { "module" },
      },
    },
  },
  exclude = {
    -- Upstream defaults (minus packer/telescope, not in the stack) + side panels.
    filetypes = {
      "",
      "checkhealth",
      "help",
      "man",
      "lspinfo",
      "gitcommit",
      "lazy",
      "mason",
      "neo-tree",
      "trouble",
      "aerial",
      "dbui",
      "dap-view",
      "dap-view-term",
      "dap-repl",
    },
    buftypes = { "terminal", "nofile", "quickfix", "prompt" },
  },
}

return M
