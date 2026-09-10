-- Перенесено из старого конфига (задача 01). Опции дополняются в задаче 03.
-- TODO(задача 03): добавить шапку
-- `-- defaults verified against catppuccin vX.Y.Z (YYYY-MM-DD)` после того,
-- как остальные документированные опции catppuccin будут выписаны явно.
--
-- ВАЖНО: переопределения делаются ТОЛЬКО через `custom_highlights`,
-- никогда через `color_overrides`. Правки на уровне палитры связывают
-- `CursorLine` с `Normal`, и курсорная строка перестаёт быть различимой.
-- Прошлая версия конфига уже переезжала с палитры на per-group
-- переопределения — не откатывать.

local M = {}

-- Module-scope so the catppuccin and lualine specs below share one source.
local black = "#000000" -- TODO(задача 03): переехать в user/settings.lua → colorscheme.window_bg

M.opts = {
  flavour = "mocha", -- Variants: latte, frappe, macchiato, mocha
  -- Per-group overrides (not `color_overrides`) so `CursorLine` can stay
  -- separable from `Normal` — palette-level edits coupled them together.
  custom_highlights = function(colors)
    local window_bg = black
    local window_cursor_bg = colors.crust
    local float_bg = black
    local float_cursor_bg = colors.mantle
    local float_fg = colors.blue
    local picker_preview_line_bg = colors.base

    return {
      -- Editor surfaces.
      Normal = { bg = window_bg },
      NormalNC = { bg = window_bg },
      SignColumn = { bg = window_bg },
      LineNr = { bg = window_bg },
      CursorLineNr = { bg = window_cursor_bg },
      CursorLine = { bg = window_cursor_bg },
      StatusLine = { bg = window_bg },
      StatusLineNC = { bg = window_bg },

      -- Neo-tree surfaces. Neo-tree's built-in `winhighlight` already
      -- remaps these, so defining the groups is enough. `CursorLine` is
      -- the exception — appended in the event handler below.
      NeoTreeNormal = { bg = window_bg },
      NeoTreeNormalNC = { bg = window_bg },
      NeoTreeEndOfBuffer = { bg = window_bg },
      NeoTreeWinSeparator = { bg = window_bg },
      NeoTreeCursorLine = { bg = window_cursor_bg },

      -- Generic floating-window baseline: LSP hover, `vim.ui.select`,
      -- the `Snacks.lazygit()` terminal float, and any future plugin
      -- that uses the stock groups. nvim-cmp's `bordered()` windows
      -- remap `Normal` and `FloatBorder` to `Pmenu` / `CmpDocBorder`
      -- via `winhighlight`, so the completion menu is unaffected.
      -- TODO(задача 03/06): nvim-cmp и lazygit из стека ушли (blink.cmp,
      -- neogit) — перепроверить, кто теперь remap'ит эти группы.
      NormalFloat = { bg = float_bg },
      FloatBorder = { bg = float_bg, fg = float_fg },
      FloatTitle = { bg = float_bg, fg = float_fg },

      -- Picker windows. Значения цветов перенесены из Telescope-блока
      -- старого конфига один-в-один, поменялись только имена групп
      -- (telescope → fzf-lua, задача 10). Исходный комментарий сохранён,
      -- он объясняет, почему хватило одной группы выделения:
      --   "Telescope sets `winhighlight` so the results window's
      --    `CursorLine` is remapped to `TelescopeSelection` — overriding
      --    that group here is enough to color the selected row, no
      --    per-buffer autocmd needed."
      -- TODO(задача 10): проверить, как то же самое устроено в fzf-lua.
      FzfLuaNormal = { bg = float_bg },
      FzfLuaPreviewNormal = { bg = float_bg },
      FzfLuaBorder = { bg = float_bg, fg = float_fg },
      FzfLuaPreviewBorder = { bg = float_bg, fg = float_fg },
      FzfLuaCursorLine = { bg = float_cursor_bg },
      FzfLuaCursorLineNr = { bg = float_cursor_bg },
      FzfLuaPreviewTitle = { bg = picker_preview_line_bg },
    }
  end,
}

-- Производная от «чёрной» схемы выше: тема lualine с обнулёнными фонами
-- секций. Вызывается из `settings/lualine.lua` (задача 03).
-- TODO(задача 03): flavour захардкожен в имени модуля темы — связать
-- с `M.opts.flavour`, когда базовый цвет переедет в user/settings.lua.
function M.lualine_theme()
  -- Theme required as a table (not the `"catppuccin-mocha"` string) so
  -- per-section colors can be edited. Black out `b`/`c` (mirrored to
  -- `y`/`x`); leave `a` on its catppuccin blue.
  local theme = require("lualine.themes.catppuccin-mocha")
  for _, mode in pairs(theme) do
    if mode.b then
      mode.b.bg = black
    end
    if mode.c then
      mode.c.bg = black
    end
  end
  return theme
end

-- Тоже производная от схемы: без этого хендлера группа `NeoTreeCursorLine`,
-- определённая в `custom_highlights`, никуда не подключается.
-- Вызывается из `settings/neo-tree.lua` как `event_handlers` (задача 05).
function M.neo_tree_cursorline()
  return {
    -- Neo-tree's built-in `winhighlight` doesn't include `CursorLine`;
    -- append the remap so the tree gets a visible cursor row.
    -- Appended (not assigned) to preserve neo-tree's own `Normal`/
    -- `NormalNC`/`EndOfBuffer` remaps.
    event = "neo_tree_buffer_enter",
    handler = function()
      vim.wo.cursorline = true
      vim.wo.cursorlineopt = "both"
      local current = vim.wo.winhighlight
      local addition = "CursorLine:NeoTreeCursorLine"
      if not current:find(addition, 1, true) then
        vim.wo.winhighlight = current == "" and addition or current .. "," .. addition
      end
    end,
  }
end

return M
