local spec = require("settings").spec

return {
  spec("smjonas/inc-rename.nvim", "refactor.inc-rename"),
  spec("ThePrimeagen/refactoring.nvim", "refactor.refactoring", {
    dependencies = { "lewis6991/async.nvim" },
  }),
  spec("lewis6991/async.nvim"),
  spec("jake-stewart/multicursor.nvim", "refactor.multicursor"),
}
