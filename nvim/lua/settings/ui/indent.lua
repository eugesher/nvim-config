local M = {}

M.event = { "BufReadPost", "BufNewFile" }

M.opts = {
  enabled = true,
  debounce = 200,
  viewport_buffer = { min = 30 },
  indent = {
    char = "│",
    tab_char = "»",
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
    show_start = false,
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
