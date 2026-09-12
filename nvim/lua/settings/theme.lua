-- defaults verified against catppuccin v2.0.0-16-gedefef7 (2026-09-11)
--
-- IMPORTANT: overrides go ONLY through `custom_highlights`, never through
-- `color_overrides`. Palette-level edits tie `CursorLine` to `Normal`, and the
-- cursor line can no longer be told apart.

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
  -- Per-flavor variant of `custom_highlights`; unused — one scheme for all flavors.
  highlight_overrides = {},
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

      -- Generic floating-window baseline: LSP hover, `vim.ui.select` and any
      -- plugin that uses the stock groups. blink.cmp falls back to `Pmenu` /
      -- `NormalFloat`, so its own groups are set explicitly below.
      NormalFloat = { bg = float_bg },
      FloatBorder = { bg = float_bg, fg = float_fg },
      FloatTitle = { bg = float_bg, fg = float_fg },

      -- Picker windows (fzf-lua). The selected row of the list uses
      -- `FzfLuaFzfCursorLine`, which links to `FzfLuaCursorLine` — the group of
      -- the preview's cursor line too, so one group colors both.
      FzfLuaNormal = { bg = float_bg },
      FzfLuaPreviewNormal = { bg = float_bg },
      FzfLuaBorder = { bg = float_bg, fg = float_fg },
      FzfLuaPreviewBorder = { bg = float_bg, fg = float_fg },
      FzfLuaCursorLine = { bg = float_cursor_bg },
      FzfLuaCursorLineNr = { bg = float_cursor_bg },

      -- Plugin surfaces below follow the same scheme: base black background,
      -- `crust` / `mantle` for the cursor row, `blue` for borders and titles.

      -- Completion menu, docs and signature help (blink.cmp).
      BlinkCmpMenu = { bg = float_bg },
      BlinkCmpMenuBorder = { bg = float_bg, fg = float_fg },
      BlinkCmpMenuSelection = { bg = float_cursor_bg },
      BlinkCmpDoc = { bg = float_bg },
      BlinkCmpDocBorder = { bg = float_bg, fg = float_fg },
      BlinkCmpSignatureHelp = { bg = float_bg },
      BlinkCmpSignatureHelpBorder = { bg = float_bg, fg = float_fg },

      -- Git panels (neogit, diffview).
      NeogitNormal = { bg = window_bg },
      NeogitCursorLine = { bg = window_cursor_bg },
      DiffviewNormal = { bg = window_bg },
      DiffviewEndOfBuffer = { bg = window_bg },
      DiffviewWinSeparator = { bg = window_bg },
      DiffviewCursorLine = { bg = window_cursor_bg },

      -- Debugger (nvim-dap). Catppuccin's `dap` integration colors
      -- the signs themselves (DapBreakpoint, DapStopped, …); the line the
      -- debugger stopped on has no group of its own — it must stand out more
      -- than `CursorLine`, hence `surface1` instead of `crust`.
      DapStoppedLine = { bg = colors.surface1 },

      -- Debugger panels (nvim-dap-view). Its windows use plain `Normal` /
      -- `NormalFloat`; only the tab bar has groups of its own.
      NvimDapViewTabFill = { bg = window_bg },
      NvimDapViewTab = { bg = window_bg },
      NvimDapViewTabSelected = { bg = window_cursor_bg, fg = float_fg },

      -- Test runner (neotest): window-picker label, float borders.
      NeotestWinSelect = { fg = float_fg, bold = true },
      NeotestBorder = { bg = float_bg, fg = float_fg },

      -- Multiple cursors (multicursor.nvim). The plugin defines the
      -- same groups with `default = true`, so these win. `MultiCursorCursor`
      -- must read as a cursor rather than a selection: inverted `peach` instead
      -- of the `Visual` background the other groups link to.
      MultiCursorCursor = { bg = colors.peach, fg = window_bg },
      MultiCursorVisual = { link = "Visual" },
      MultiCursorSign = { fg = colors.peach },
      MultiCursorMatchPreview = { link = "Search" },
      MultiCursorDisabledCursor = { bg = colors.overlay0, fg = window_bg },
      MultiCursorDisabledVisual = { bg = colors.surface1 },
      MultiCursorDisabledSign = { fg = colors.overlay0 },

      -- Problems panel (trouble.nvim).
      TroubleNormal = { bg = window_bg },
      TroubleNormalNC = { bg = window_bg },

      -- Outline and breadcrumbs (aerial, dropbar). dropbar's menu is
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
  -- A table only counts with `enabled = true`. Not listed because catppuccin v2
  -- has no such integration: `treesitter` (its groups are always on) and
  -- `native_lsp` (now the top-level `lsp_styles`). bufferline and lualine are
  -- themed from their own settings files.
  integrations = {
    indent_blankline = { enabled = true, scope_color = "", colored_indent_levels = false },
    which_key = true,
    treesitter_context = true,
    mason = true,
    blink_cmp = { enabled = true, style = "bordered" },
    fzf = true,
    neotree = true,
    gitsigns = true,
    neogit = true,
    diffview = true,
    dap = true,
    dap_ui = true,
    neotest = true,
    lsp_trouble = true,
    aerial = true,
    dropbar = { enabled = true, color_mode = false },
    dadbod_ui = true,
    telescope = false, -- not used: fzf-lua is the picker
    illuminate = false,
  },
}

function M.config(_, opts)
  require("catppuccin").setup(opts)
  vim.cmd.colorscheme("catppuccin")
end

-- lualine theme for settings/lualine.lua: catppuccin's theme as a table, with
-- the `b` / `c` sections (mirrored to `y` / `x`) on the base black; `a` keeps
-- its catppuccin blue.
function M.lualine_theme()
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

-- neo-tree event handler for settings/neotree.lua. Neo-tree's own
-- `winhighlight` has no `CursorLine` remap, so without this handler
-- `NeoTreeCursorLine` is never used. The remap is appended, not assigned, to
-- keep neo-tree's `Normal` / `NormalNC` / `EndOfBuffer` remaps.
function M.neo_tree_cursorline()
  return {
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
