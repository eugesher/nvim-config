-- Problems panel: every diagnostic, reference and TODO of the project in one
-- list with a preview. trouble.nvim v3 — a rewrite of v2 that shares neither
-- its options nor its API, so pre-2024 recipes do not apply here.

local spec = require("settings").spec

return {
  spec("folke/trouble.nvim", "problems.trouble", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  spec("folke/todo-comments.nvim", "problems.todo-comments", {
    dependencies = { "nvim-lua/plenary.nvim" },
  }),
}
