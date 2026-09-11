-- Treesitter: parsers (main branch — a different plugin from the old master),
-- syntax-aware text objects, sticky context header.

local spec = require("settings").spec

return {
  spec("nvim-treesitter/nvim-treesitter", "treesitter", {
    branch = "main",
    build = ":TSUpdate", -- parsers must match the plugin's queries after every update
  }),
  spec("nvim-treesitter/nvim-treesitter-textobjects", "treesitter-textobjects", {
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  }),
  spec("nvim-treesitter/nvim-treesitter-context", "treesitter-context"),
}
