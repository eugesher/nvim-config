local M = {}

M.event = { "BufReadPost", "BufNewFile" }

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
  multiwindow = false,
  max_lines = 3,
  min_window_height = 20,
  line_numbers = true,
  multiline_threshold = 20,
  trim_scope = "outer",
  mode = "cursor",
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
