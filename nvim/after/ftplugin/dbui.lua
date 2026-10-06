local db = require("settings.database.dadbod")

local KEYMAPS = {
  { "q", db.toggle_tab, "Close database tab" },
  { "<C-j>", db.goto_results, "Go to query results" },
}

local undo = {}
for _, map in ipairs(KEYMAPS) do
  vim.keymap.set("n", map[1], map[2], { buffer = true, nowait = true, desc = map[3] })
  undo[#undo + 1] = ("silent! nunmap <buffer> %s"):format(map[1])
end
vim.b.undo_ftplugin = table.concat(vim.list_extend({ vim.b.undo_ftplugin }, undo), "|")
