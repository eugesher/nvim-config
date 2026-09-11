-- Picker for files, text, symbols, diagnostics and git; also serves vim.ui.select.
-- Telescope is not used anywhere in this config (decision recorded in task 10).

return require("settings").spec("ibhagwan/fzf-lua", "fzf", {
  dependencies = { "nvim-tree/nvim-web-devicons" },
})
