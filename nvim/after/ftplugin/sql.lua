local db = require("settings.database.dadbod")

local KEYMAPS = {
  { "n", "<localleader>x", db.execute_statement, "Execute statement under cursor" },
  { "x", "<localleader>x", db.execute_selection, "Execute selection" },
  { "n", "<localleader>X", db.execute_buffer, "Execute buffer" },
  { "n", "<localleader>w", db.save_query, "Save query" },
  { "n", "<localleader>e", db.edit_bind_parameters, "Edit bind parameters" },
}

local undo = {}
for _, map in ipairs(KEYMAPS) do
  vim.keymap.set(map[1], map[2], map[3], { buffer = true, desc = map[4] })
  undo[#undo + 1] = ("silent! %sunmap <buffer> %s"):format(map[1], map[2])
end
vim.b.undo_ftplugin = table.concat(vim.list_extend({ vim.b.undo_ftplugin }, undo), "|")
