-- defaults verified against catppuccin v2.0.0-16-gedefef7 (2026-09-11)
--
-- Перенесено из старого конфига (задача 01), дополнено в задаче 03.
--
-- ВАЖНО: переопределения делаются ТОЛЬКО через `custom_highlights`,
-- никогда через `color_overrides`. Правки на уровне палитры связывают
-- `CursorLine` с `Normal`, и курсорная строка перестаёт быть различимой.
-- Прошлая версия конфига уже переезжала с палитры на per-group
-- переопределения — не откатывать.

local user = require("user.settings")

local M = {}

-- Module-scope so the catppuccin and lualine specs below share one source.
-- Comes from user/settings.lua (`colorscheme.window_bg`); with
-- `colorscheme.transparent` the surfaces show the terminal background instead.
local black = user.colorscheme.transparent and "NONE" or user.colorscheme.window_bg

-- Eager and first: every other UI plugin reads its palette and groups.
M.lazy = false
M.priority = 1000

M.opts = {
  flavour = user.colorscheme.flavour, -- Variants: latte, frappe, macchiato, mocha
  background = { light = "latte", dark = "mocha" }, -- used only by `flavour = "auto"`
  compile_path = vim.fn.stdpath("cache") .. "/catppuccin",
  transparent_background = user.colorscheme.transparent,
  float = {
    transparent = false, -- floats keep their own (black) background
    solid = false, -- keep the 'winborder' borders
  },
  term_colors = true, -- :terminal buffers (debug console, test output) use the palette
  dim_inactive = { enabled = false, shade = "dark", percentage = 0.15 },
  no_italic = false,
  no_bold = false,
  no_underline = false,
  styles = {
    comments = { "italic" },
    conditionals = { "italic" },
    loops = {},
    functions = {},
    keywords = {},
    strings = {},
    variables = {},
    numbers = {},
    booleans = {},
    properties = {},
    types = {},
    operators = {},
  },
  -- Built-in LSP/diagnostic groups. Catppuccin v2 moved this here from
  -- `integrations.native_lsp`.
  lsp_styles = {
    virtual_text = {
      errors = { "italic" },
      hints = { "italic" },
      warnings = { "italic" },
      information = { "italic" },
      ok = { "italic" },
    },
    underlines = {
      errors = { "underline" },
      hints = { "underline" },
      warnings = { "underline" },
      information = { "underline" },
      ok = { "underline" },
    },
    inlay_hints = { background = true },
  },
  -- Intentionally empty: see the rule at the top of the file.
  color_overrides = {},
  -- Per-flavour variant of `custom_highlights`; unused — one scheme for all flavours.
  highlight_overrides = {},
  -- Per-group overrides (not `color_overrides`) so `CursorLine` can stay
  -- separable from `Normal` — palette-level edits coupled them together.
  custom_highlights = function(colors)
    local window_bg = black
    local window_cursor_bg = colors.crust
    local float_bg = black
    local float_cursor_bg = colors.mantle
    local float_fg = colors.blue

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
      -- Задача 03: nvim-cmp и lazygit из стека ушли. blink.cmp по умолчанию
      -- берёт `Pmenu`/`NormalFloat` — его группы заданы явно ниже.
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
      -- Проверено в задаче 10: выделенная строка списка fzf берёт цвет из
      -- `FzfLuaFzfCursorLine`, которая по умолчанию ссылается на
      -- `FzfLuaCursorLine` — эту же группу использует курсорная строка превью.
      -- Бывший `TelescopePreviewLine` (строка совпадения в превью) убран: у
      -- fzf-lua нет такой группы, её роль играет курсорная строка превью, а
      -- `FzfLuaPreviewTitle` — это заголовок окна превью, он остаётся как в теме.
      FzfLuaNormal = { bg = float_bg },
      FzfLuaPreviewNormal = { bg = float_bg },
      FzfLuaBorder = { bg = float_bg, fg = float_fg },
      FzfLuaPreviewBorder = { bg = float_bg, fg = float_fg },
      FzfLuaCursorLine = { bg = float_cursor_bg },
      FzfLuaCursorLineNr = { bg = float_cursor_bg },

      -- Задача 03: поверхности плагинов, которых в старом конфиге не было.
      -- Та же логика: фон — базовый чёрный, курсор/выделение — `crust`/`mantle`,
      -- рамка/заголовок — `blue`. Объявлены заранее: неизвестная группа безвредна.

      -- Completion menu, docs and signature help (blink.cmp, задача 08).
      BlinkCmpMenu = { bg = float_bg },
      BlinkCmpMenuBorder = { bg = float_bg, fg = float_fg },
      BlinkCmpMenuSelection = { bg = float_cursor_bg },
      BlinkCmpDoc = { bg = float_bg },
      BlinkCmpDocBorder = { bg = float_bg, fg = float_fg },
      BlinkCmpSignatureHelp = { bg = float_bg },
      BlinkCmpSignatureHelpBorder = { bg = float_bg, fg = float_fg },

      -- Git panels (neogit, diffview — задача 13).
      NeogitNormal = { bg = window_bg },
      NeogitCursorLine = { bg = window_cursor_bg },
      DiffviewNormal = { bg = window_bg },
      DiffviewEndOfBuffer = { bg = window_bg },
      DiffviewWinSeparator = { bg = window_bg },
      DiffviewCursorLine = { bg = window_cursor_bg },

      -- Debugger (nvim-dap, задача 16). Catppuccin's `dap` integration colors
      -- the signs themselves (DapBreakpoint, DapStopped, …); the line the
      -- debugger stopped on has no group of its own — it must stand out more
      -- than `CursorLine`, hence `surface1` instead of `crust`.
      DapStoppedLine = { bg = colors.surface1 },

      -- Debugger panels (nvim-dap-view, задача 17). Its windows use plain
      -- `Normal` / `NormalFloat` (covered above); only the tab bar has own groups.
      NvimDapViewTabFill = { bg = window_bg },
      NvimDapViewTab = { bg = window_bg },
      NvimDapViewTabSelected = { bg = window_cursor_bg, fg = float_fg },

      -- Test runner (neotest, задача 18): window-picker label, float borders.
      NeotestWinSelect = { fg = float_fg, bold = true },
      NeotestBorder = { bg = float_bg, fg = float_fg },

      -- Problems panel (trouble.nvim, задача 20).
      TroubleNormal = { bg = window_bg },
      TroubleNormalNC = { bg = window_bg },

      -- Outline and breadcrumbs (aerial, dropbar — задача 26). dropbar's menu is
      -- a float: the group is `DropBarMenuNormalFloat`, `DropBarMenuNormal` doesn't exist.
      AerialNormal = { bg = window_bg },
      AerialLine = { bg = window_cursor_bg },
      DropBarMenuNormalFloat = { bg = float_bg },
      DropBarMenuFloatBorder = { bg = float_bg, fg = float_fg },
      DropBarMenuHoverEntry = { bg = float_cursor_bg },
    }
  end,
  -- The list below is the single source of truth — nothing is enabled just
  -- because a plugin happens to be installed.
  auto_integrations = false,
  -- The whole planned stack, declared ahead: catppuccin skips modules it cannot
  -- find, and a table only counts with `enabled = true`. Not listed because
  -- catppuccin v2 has no such integration: `treesitter` (its groups are always
  -- on) and `native_lsp` (now the top-level `lsp_styles`). bufferline and
  -- lualine are themed from their own settings files.
  integrations = {
    indent_blankline = { enabled = true, scope_color = "", colored_indent_levels = false },
    which_key = true, -- задача 04
    treesitter_context = true, -- задача 05
    mason = true,
    blink_cmp = { enabled = true, style = "bordered" }, -- задача 08
    fzf = true, -- задача 10
    neotree = true, -- задача 11
    gitsigns = true,
    neogit = true, -- задача 13
    diffview = true, -- задача 13
    dap = true, -- задача 16
    dap_ui = true,
    neotest = true, -- задача 18
    lsp_trouble = true, -- задача 20
    aerial = true, -- задача 26
    dropbar = { enabled = true, color_mode = false }, -- задача 26
    dadbod_ui = true,
    telescope = false, -- replaced by fzf-lua
    illuminate = false,
  },
}

function M.config(_, opts)
  require("catppuccin").setup(opts)
  vim.cmd.colorscheme("catppuccin")
end

-- Производная от «чёрной» схемы выше: тема lualine с обнулёнными фонами
-- секций. Вызывается из `settings/lualine.lua`.
function M.lualine_theme()
  -- Theme required as a table (not the `"catppuccin-mocha"` string) so
  -- per-section colors can be edited. Black out `b`/`c` (mirrored to
  -- `y`/`x`); leave `a` on its catppuccin blue.
  local theme = require("lualine.themes.catppuccin-" .. user.colorscheme.flavour)
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
-- Вызывается из `settings/neotree.lua` как `event_handlers` (задача 11).
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
