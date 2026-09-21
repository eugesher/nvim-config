local function kulala(method)
  return function()
    require("kulala")[method]()
  end
end
local function ui(method)
  return function()
    require("kulala.ui")[method]()
  end
end

local KEYMAPS = {
  { { "n", "x" }, "<leader>hh", kulala("run"), "Run request under cursor" },
  { { "n", "x" }, "<leader>ha", kulala("run_all"), "Run all requests" },
  { "n", "<leader>hr", kulala("replay"), "Replay last request" },
  { "n", "<leader>hn", kulala("jump_next"), "Next request" },
  { "n", "<leader>hp", kulala("jump_prev"), "Previous request" },
  { "n", "<leader>he", kulala("set_selected_env"), "Select environment" },
  { "n", "<leader>hb", ui("show_body"), "Show body" },
  { "n", "<leader>hH", ui("show_headers"), "Show headers" },
  { "n", "<leader>hs", ui("show_headers_body"), "Show headers and body" },
  { "n", "<leader>hx", kulala("close"), "Close response window" },
  { "n", "<leader>hc", kulala("copy"), "Copy as curl" },
  { "n", "<leader>hi", kulala("inspect"), "Inspect request (dry run)" },
  { "n", "<leader>hS", kulala("scratchpad"), "Scratchpad" },
  { "n", "<leader>hI", kulala("open_openapi_explorer"), "OpenAPI explorer" },
  { "n", "<leader>hE", kulala("export"), "Export to Postman" },
  { "n", "<leader>hX", kulala("scripts_clear_global"), "Clear script variables" },
}

local undo = {}
for _, map in ipairs(KEYMAPS) do
  vim.keymap.set(map[1], map[2], map[3], { buffer = true, desc = map[4] })
  for _, mode in ipairs(type(map[1]) == "table" and map[1] or { map[1] }) do
    undo[#undo + 1] = ("silent! %sunmap <buffer> %s"):format(mode, map[2])
  end
end
vim.b.undo_ftplugin = table.concat(vim.list_extend({ vim.b.undo_ftplugin }, undo), "|")
