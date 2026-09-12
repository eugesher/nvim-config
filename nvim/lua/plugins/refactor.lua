-- Refactoring: live-preview rename (inc-rename) and the tree-sitter powered
-- extract / inline operators (refactoring.nvim). The latter needs async.nvim —
-- not plenary, despite what older recipes say.

local spec = require("settings").spec

return {
  spec("smjonas/inc-rename.nvim", "inc-rename"),
  spec("ThePrimeagen/refactoring.nvim", "refactoring", {
    dependencies = { "lewis6991/async.nvim" },
  }),
  spec("lewis6991/async.nvim"),
}
