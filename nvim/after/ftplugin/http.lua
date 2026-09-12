-- .http request buffers: the whole <leader>h namespace. Buffer-local on
-- purpose — kulala's own global keymaps are off (settings/kulala.lua), so in
-- other buffers the group stays empty.
--
-- The result window has its own keys (B / H / A / V / S / ] / [ / q …),
-- listed in settings/kulala.lua.

-- Loaded lazily: this file runs on FileType, kulala itself loads through the
-- same event, so the module is required only when a key is pressed.
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
  -- Running requests. Visual mode runs every request in the selection.
  { { "n", "x" }, "<leader>hh", kulala("run"), "Run request under cursor" },
  { { "n", "x" }, "<leader>ha", kulala("run_all"), "Run all requests" },
  { "n", "<leader>hr", kulala("replay"), "Replay last request" },
  -- Navigation and environments.
  { "n", "<leader>hn", kulala("jump_next"), "Next request" },
  { "n", "<leader>hp", kulala("jump_prev"), "Previous request" },
  { "n", "<leader>he", kulala("set_selected_env"), "Select environment" },
  -- Response views.
  { "n", "<leader>hb", ui("show_body"), "Show body" },
  { "n", "<leader>hH", ui("show_headers"), "Show headers" },
  { "n", "<leader>hs", ui("show_headers_body"), "Show headers and body" },
  { "n", "<leader>hx", kulala("close"), "Close response window" },
  -- Request itself.
  { "n", "<leader>hc", kulala("copy"), "Copy as curl" },
  { "n", "<leader>hi", kulala("inspect"), "Inspect request (dry run)" },
  { "n", "<leader>hS", kulala("scratchpad"), "Scratchpad" },
  -- OpenAPI explorer instead of a collection import: kulala 6.x imports
  -- neither Postman nor Bruno collections.
  { "n", "<leader>hI", kulala("open_openapi_explorer"), "OpenAPI explorer" },
  { "n", "<leader>hE", kulala("export"), "Export to Postman" },
  -- Values stored by post-request scripts (client.global.set) persist in
  -- kulala-core's database between restarts — tokens included.
  { "n", "<leader>hX", kulala("scripts_clear_global"), "Clear script variables" },
}

local undo = {}
for _, map in ipairs(KEYMAPS) do
  vim.keymap.set(map[1], map[2], map[3], { buffer = true, desc = map[4] })
  for _, mode in ipairs(type(map[1]) == "table" and map[1] or { map[1] }) do
    undo[#undo + 1] = ("silent! %sunmap <buffer> %s"):format(mode, map[2])
  end
end
-- Removed again when the buffer switches to another filetype. No space before
-- `|`: :unmap takes trailing whitespace as part of the {lhs}.
vim.b.undo_ftplugin = table.concat(vim.list_extend({ vim.b.undo_ftplugin }, undo), "|")
