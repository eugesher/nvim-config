-- Picker for files, text, symbols, diagnostics and git; also serves vim.ui.select.
-- Telescope is not used anywhere in this config.

return require("settings").spec("ibhagwan/fzf-lua", "finder.fzf", {
  dependencies = { "nvim-tree/nvim-web-devicons" },
})
