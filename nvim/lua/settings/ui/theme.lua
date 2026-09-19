local user = require("user.settings")

local M = {}

local enabled = user.colorscheme.enabled

local black = user.colorscheme.transparent and "NONE" or user.colorscheme.window_bg

M.cond = enabled
M.lazy = false
M.priority = 1000

M.opts = {
  flavour = user.colorscheme.flavour,
  background = { light = "latte", dark = "mocha" },
  compile_path = vim.fn.stdpath("cache") .. "/catppuccin",
  transparent_background = user.colorscheme.transparent,
  float = {
    transparent = user.colorscheme.transparent_floats,
    solid = false,
  },
  term_colors = true,
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
  color_overrides = {},
  highlight_overrides = {},
  custom_highlights = function(colors)
    return {
      LineNr = { fg = colors.surface2 },
      WinBar = {
        sp = user.colorscheme.transparent and colors.dim or colors.surface0,
        -- style = { "underline" },
      },
      -- TabLineFill = { underline = true },
    }
  end,
  auto_integrations = false,
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
    telescope = false,
    illuminate = false,
  },
}

function M.config(_, opts)
  require("catppuccin").setup(opts)
  vim.cmd.colorscheme("catppuccin")
end

function M.palette()
  if not enabled then
    return nil
  end
  return require("catppuccin.palettes").get_palette()
end

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

function M.bufferline_highlights()
  if not enabled then
    return {}
  end
  return require("catppuccin.special.bufferline").get_theme({ styles = { "bold" } })
end

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
