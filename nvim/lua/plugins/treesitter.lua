-- ~/.config/nvim/lua/plugins/treesitter.lua
-- Treesitter: AST-based syntax highlighting, indentation, and navigation.

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate", -- Update parsers after install/update
  event = "BufReadPost", -- Load when a file is opened
  config = function()
    require("nvim-treesitter").setup({
      -- Parsers to install
      ensure_installed = {
        "typescript",
        "tsx", -- React JSX/TSX
        "javascript",
        "json",
        "yaml",
        "html",
        "css",
        "lua",
        "bash",
        "markdown",
        "markdown_inline",
        "dockerfile",
        "gitignore",
      },

      -- Improved syntax highlighting
      highlight = { enable = true },

      -- AST-aware indentation
      indent = { enable = true },

      -- Incremental selection: press Enter to expand the selection
      -- along syntax nodes (word -> expression -> block -> function).
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<CR>", -- Start a selection
          node_incremental = "<CR>", -- Grow to the next node
          node_decremental = "<BS>", -- Shrink the selection
          scope_incremental = false,
        },
      },
    })
  end,
}
