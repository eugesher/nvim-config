vim.opt_local.wrap = true
vim.opt_local.linebreak = true

vim.b.undo_ftplugin =
  table.concat(vim.list_extend({ vim.b.undo_ftplugin }, { "setlocal wrap< linebreak<" }), "|")
