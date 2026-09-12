-- Refactoring: live-preview rename (inc-rename), the tree-sitter powered
-- extract / inline operators (refactoring.nvim) and multiple cursors. The
-- second needs async.nvim — not plenary, despite what older recipes say.

local spec = require("settings").spec

return {
  spec("smjonas/inc-rename.nvim", "refactor.inc-rename"),
  spec("ThePrimeagen/refactoring.nvim", "refactor.refactoring", {
    dependencies = { "lewis6991/async.nvim" },
  }),
  spec("lewis6991/async.nvim"),
  -- Not vim-visual-multi: vimscript, and known trouble with LSP and completion
  -- plugins.
  spec("jake-stewart/multicursor.nvim", "refactor.multicursor"),
}
