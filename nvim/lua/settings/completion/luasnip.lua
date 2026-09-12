-- defaults verified against LuaSnip v2.5.0 (2026-09-11)
--
-- Snippet engine behind blink.cmp (`snippets.preset = "luasnip"`): VSCode
-- snippets from friendly-snippets and our own Lua snippets in lua/snippets/.

local icons = require("settings.icons")

local M = {}

-- A function: `ext_opts` needs luasnip.util.types, available once LuaSnip is loaded.
function M.opts()
  local types = require("luasnip.util.types")
  return {
    -- What `history = true` meant before v2 (the option is deprecated): keep and
    -- link snippet roots, so an expanded snippet can be re-entered with <Tab>.
    keep_roots = true,
    link_roots = true,
    link_children = true,
    exit_roots = false,
    update_events = "TextChanged,TextChangedI", -- repeated nodes follow as you type
    delete_check_events = "TextChanged", -- forget snippets whose text was deleted
    region_check_events = "CursorMoved", -- leave the snippet once the cursor leaves it
    enable_autosnippets = false,
    -- Visual <Tab> stores the selection for $TM_SELECTED_TEXT
    -- (`store_selection_keys` is the deprecated name).
    cut_selection_keys = "<Tab>",
    -- Marker at the end of the line for the active node.
    ext_opts = {
      [types.insertNode] = { active = { virt_text = { { icons.ui.dot, "DiagnosticHint" } } } },
      [types.choiceNode] = {
        active = { virt_text = { { icons.ui.dot .. " choice", "DiagnosticWarn" } } },
      },
    },
  }
end

function M.config(_, opts)
  require("luasnip").setup(opts)
  require("luasnip.loaders.from_vscode").lazy_load() -- friendly-snippets, found on 'runtimepath'
  require("luasnip.loaders.from_lua").lazy_load({
    paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
  })
end

return M
