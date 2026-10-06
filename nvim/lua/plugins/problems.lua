local spec = require("settings").spec

return {
  spec("folke/trouble.nvim", "problems.trouble", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  spec("folke/todo-comments.nvim", "problems.todo-comments", {
    dependencies = { "nvim-lua/plenary.nvim" },
  }),
}
