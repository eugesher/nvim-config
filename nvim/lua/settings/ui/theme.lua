-- defaults verified against catppuccin v2.0.0-16-gedefef7 (2026-09-11)
--
-- IMPORTANT: overrides go ONLY through `custom_highlights`, never through
-- `color_overrides`. Palette-level edits tie `CursorLine` to `Normal`, and the
-- cursor line can no longer be told apart.
--
-- `user.colorscheme.enabled = false` turns all of it off: catppuccin is not
-- loaded, Neovim keeps its default colorscheme, and the helpers at the bottom
-- hand the other plugins their own default colors. Color code elsewhere goes
-- through those helpers and never requires catppuccin itself: lazy.nvim raises
-- an error on a `require` of a plugin whose `cond` is false.

local user = require("user.settings")

local M = {}

local enabled = user.colorscheme.enabled

-- Module-scope so the catppuccin and lualine specs below share one source.
-- Comes from user/settings.lua (`colorscheme.window_bg`); with
-- `colorscheme.transparent` the surfaces show the terminal background instead.
local black = user.colorscheme.transparent and "NONE" or user.colorscheme.window_bg

-- `cond`, not `enabled`: the plugin stays installed and in lazy-lock.json, so
-- switching the colorscheme back on needs no download.
M.cond = enabled
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
    return {
      -- A rule under the winbar, so the breadcrumbs (dropbar) don't blend into
      -- the code: the same one catppuccin draws under the sticky context
      -- (`TreesitterContextBottom`). Merged into catppuccin's `WinBar`, which
      -- keeps its foreground; winbar items stack on this group, so the rule
      -- spans the window. `WinBarNC` links here, and dropbar dims nothing.
      WinBar = {
        sp = user.colorscheme.transparent and colors.dim or colors.surface0,
        style = { "underline" },
      },
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

-- Helpers for the other settings modules. With the colorscheme off each one
-- returns what leaves the plugin on its own defaults.

--- Palette of the active catppuccin flavor (`red`, `green`, …); nil when the
--- colorscheme is off.
---@return table<string, string>?
function M.palette()
  if not enabled then
    return nil
  end
  return require("catppuccin.palettes").get_palette()
end

-- lualine theme for settings/ui/lualine.lua: catppuccin's theme as a table, with
-- the `b` / `c` sections (mirrored to `y` / `x`) on the base black; `a` keeps
-- its catppuccin blue. Colorscheme off: lualine's default "auto", built from the
-- groups of the active colorscheme.
function M.lualine_theme()
  if not enabled then
    return "auto"
  end
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

-- `highlights` for settings/ui/bufferline.lua: catppuccin's bufferline theme,
-- the selected tab bold instead of italic. Colorscheme off: none, so bufferline
-- derives its groups from the active colorscheme.
function M.bufferline_highlights()
  if not enabled then
    return {}
  end
  return require("catppuccin.special.bufferline").get_theme({ styles = { "bold" } })
end

-- neo-tree event handlers for settings/explorer/neotree.lua. Neo-tree's own
-- `winhighlight` has no `CursorLine` remap, so without this handler
-- `NeoTreeCursorLine` is never used. The remap is appended, not assigned, to
-- keep neo-tree's `Normal` / `NormalNC` / `EndOfBuffer` remaps. Colorscheme
-- off: no handler, neo-tree's own cursor line.
---@return table[]
function M.neo_tree_handlers()
  if not enabled then
    return {}
  end
  return {
    {
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
    },
  }
end

return M
