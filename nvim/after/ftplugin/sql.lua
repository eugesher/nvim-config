-- SQL query buffers: run the statement under the cursor, the selection or the
-- whole buffer; save a query opened from the drawer. vim-dadbod-ui's own
-- <Leader>S / <Leader>W / <Leader>E are off (settings/dadbod.lua), and :w never
-- runs anything. Also sourced for mysql and plsql buffers
-- (after/ftplugin/mysql.lua, plsql.lua).

local db = require("settings.dadbod")

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
-- Removed again when the buffer switches to another filetype. No space before
-- `|`: :unmap takes trailing whitespace as part of the {lhs}.
vim.b.undo_ftplugin = table.concat(vim.list_extend({ vim.b.undo_ftplugin }, undo), "|")
