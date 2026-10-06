local spec = require("settings").spec

return {
  spec("nvim-treesitter/nvim-treesitter", "treesitter.treesitter", {
    branch = "main",
    build = ":TSUpdate",
  }),
  spec("nvim-treesitter/nvim-treesitter-textobjects", "treesitter.treesitter-textobjects", {
    branch = "main",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  }),
  spec("nvim-treesitter/nvim-treesitter-context", "treesitter.treesitter-context"),
}
