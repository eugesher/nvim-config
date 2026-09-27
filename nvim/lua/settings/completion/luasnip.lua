local icons = require("settings.icons")

local M = {}

function M.opts()
  local types = require("luasnip.util.types")
  return {
    keep_roots = true,
    link_roots = true,
    link_children = true,
    exit_roots = false,
    update_events = "TextChanged,TextChangedI",
    delete_check_events = "TextChanged",
    region_check_events = "CursorMoved",
    enable_autosnippets = false,
    cut_selection_keys = "<Tab>",
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
  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_lua").lazy_load({
    paths = { vim.fn.stdpath("config") .. "/lua/snippets" },
  })
end

return M
