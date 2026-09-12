-- Refactoring: live-preview rename (inc-rename), the tree-sitter powered
-- extract / inline operators (refactoring.nvim) and multiple cursors. The
-- second needs async.nvim — not plenary, despite what older recipes say.

local spec = require("settings").spec

return {
  spec("smjonas/inc-rename.nvim", "inc-rename"),
  spec("ThePrimeagen/refactoring.nvim", "refactoring", {
    dependencies = { "lewis6991/async.nvim" },
  }),
  spec("lewis6991/async.nvim"),
  -- vim-visual-multi was considered and rejected: vimscript, and known trouble
  -- with LSP and completion plugins (decision recorded in task 25).
  spec("jake-stewart/multicursor.nvim", "multicursor"),
}
