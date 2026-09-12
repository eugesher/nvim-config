-- defaults verified against aerial.nvim v4.0.0-10-g28fe6e8 (2026-09-13)
--
-- Structure view: the symbol tree of the current file in a side panel (like
-- WebStorm's Structure tool window), a miller-columns nav float and a symbol
-- picker through fzf-lua. Breadcrumbs in the winbar are dropbar's job
-- (settings/dropbar.lua); trouble's `symbols` mode is deliberately unused.

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

-- Loaded with the first file, not on the first `<leader>o`: `{` / `}` come from
-- `on_attach`, and with a key-only load they would stay paragraph motions until
-- the tree is opened once, then change meaning mid-session (task 26).
M.event = { "BufReadPost", "BufNewFile" }
M.cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle" }

M.keys = {
  { "<leader>o", "<cmd>AerialToggle<cr>", desc = "Outline (symbol tree)" },
  { "<leader>O", "<cmd>AerialNavToggle<cr>", desc = "Outline navigator" },
  {
    "<leader>fo",
    function()
      require("aerial").fzf_lua_picker()
    end,
    desc = "Outline symbols",
  },
}

-- aerial puts the icon straight in front of the name: its own glyphs carry a
-- trailing space, the shared ones (settings/icons.lua) do not.
local function kind_icons()
  local padded = {}
  for kind, glyph in pairs(icons.kinds) do
    padded[kind] = glyph .. " "
  end
  return padded
end

-- `{` / `}` jump between symbols in every buffer aerial attaches to. Counts
-- work (`3}`); outside those buffers the keys stay Vim's paragraph motions.
local function on_attach(bufnr)
  local aerial = require("aerial")
  vim.keymap.set("n", "{", function()
    aerial.prev(vim.v.count1)
  end, { buffer = bufnr, desc = "Previous symbol" })
  vim.keymap.set("n", "}", function()
    aerial.next(vim.v.count1)
  end, { buffer = bufnr, desc = "Next symbol" })
end

-- vtsls reports every anonymous function as a symbol of its own
-- (`rows.filter() callback`); the structure view lists declarations only.
local function post_parse_symbol(_, item, ctx)
  return not (
    ctx.backend_name == "lsp"
    and item.kind == "Function"
    and item.name:match(" callback$")
  )
end

M.opts = {
  -- LSP first, although task 26 asked for treesitter first: aerial's TypeScript
  -- treesitter query has no Property / Field, so class fields and NestJS
  -- injections never showed up, and a buffer attached to treesitter stays there
  -- after vtsls starts. With this order the tree is still filled at once — on
  -- first attach every backend races and treesitter answers first — and moves
  -- to vtsls when it attaches (~0.4 s later, measured).
  -- Upstream quirk: the switch is computed for the *current* buffer, so it is
  -- missed when the tree window has focus at the moment vtsls attaches. Loading
  -- on BufReadPost (above) makes that rare: the server comes up while the
  -- cursor is still in the code.
  backends = { "lsp", "treesitter", "markdown", "man" },

  layout = {
    max_width = { 40, 0.3 }, -- the lesser of 40 columns or 30% of the editor
    width = nil,
    min_width = 28,
    win_opts = {},
    default_direction = "prefer_right",
    -- At the far right of the editor, not next to the current split: the panel
    -- does not jump around when windows are split.
    placement = "edge",
    resize_to_content = true,
    preserve_equality = false,
  },

  attach_mode = "window",
  close_automatic_events = {},

  -- Keys inside the tree window.
  keymaps = {
    ["?"] = "actions.show_help",
    ["g?"] = "actions.show_help",
    ["<CR>"] = "actions.jump",
    ["<2-LeftMouse>"] = "actions.jump",
    -- The same split keys as in fzf-lua (settings/fzf.lua).
    ["<C-v>"] = "actions.jump_vsplit",
    ["<C-s>"] = "actions.jump_split",
    ["p"] = "actions.scroll",
    -- Move and scroll the code to the symbol. Inside the panel they shadow the
    -- window moves of core/keymaps.lua; the panel sits at the right edge, so
    -- only `<C-h>` has anywhere to go, and it is left alone.
    ["<C-j>"] = "actions.down_and_scroll",
    ["<C-k>"] = "actions.up_and_scroll",
    ["{"] = "actions.prev",
    ["}"] = "actions.next",
    ["[["] = "actions.prev_up",
    ["]]"] = "actions.next_up",
    ["q"] = "actions.close",
    ["o"] = "actions.tree_toggle",
    ["za"] = "actions.tree_toggle",
    ["O"] = "actions.tree_toggle_recursive",
    ["zA"] = "actions.tree_toggle_recursive",
    ["l"] = "actions.tree_open",
    ["zo"] = "actions.tree_open",
    ["L"] = "actions.tree_open_recursive",
    ["zO"] = "actions.tree_open_recursive",
    ["h"] = "actions.tree_close",
    ["zc"] = "actions.tree_close",
    ["H"] = "actions.tree_close_recursive",
    ["zC"] = "actions.tree_close_recursive",
    ["zr"] = "actions.tree_increase_fold_level",
    ["zR"] = "actions.tree_open_all",
    ["zm"] = "actions.tree_decrease_fold_level",
    ["zM"] = "actions.tree_close_all",
    ["zx"] = "actions.tree_sync_folds",
    ["zX"] = "actions.tree_sync_folds",
  },

  -- aerial's own lazy loading; lazy.nvim does that here. Passing `on_attach`
  -- turns it off anyway.
  lazy_load = false,
  disable_max_lines = 10000,
  disable_max_size = 2000000, -- bytes

  -- Property and Field: NestJS services are mostly injected fields.
  filter_kind = {
    "Class",
    "Constructor",
    "Enum",
    "Function",
    "Interface",
    "Module",
    "Method",
    "Struct",
    "Property",
    "Field",
  },

  highlight_mode = "split_width",
  highlight_closest = true,
  -- Moving through the tree marks the symbol's line in the code; the code
  -- scrolls to it with `<C-j>` / `<C-k>` or `p` (keymaps above).
  highlight_on_hover = true,
  highlight_on_jump = 300,
  autojump = false,

  icons = kind_icons(),

  ignore = {
    unlisted_buffers = false,
    diff_windows = true,
    filetypes = {},
    buftypes = "special", -- panels, terminals, prompts
    wintypes = "special", -- floats, preview windows
  },

  -- Folds stay treesitter's (core/options.lua).
  manage_folds = false,
  link_folds_to_tree = false,
  link_tree_to_folds = true,
  nerd_font = "auto",

  on_attach = on_attach,
  on_first_symbols = function(_) end,
  open_automatic = false,
  post_jump_cmd = "normal! zz",
  post_parse_symbol = post_parse_symbol,
  post_add_all_symbols = function(_, items, _)
    return items
  end,
  close_on_select = false,
  update_events = "TextChanged,InsertLeave",

  show_guides = true,
  guides = {
    mid_item = "├─",
    last_item = "└─",
    nested_top = "│ ",
    whitespace = "  ",
  },
  get_highlight = function(_, _, _) end, -- aerial's own Aerial<Kind> groups

  float = {
    border = user.ui.border,
    relative = "cursor",
    max_height = 0.9,
    height = nil,
    min_height = { 8, 0.1 },
    override = function(conf, _)
      return conf
    end,
  },

  nav = {
    border = user.ui.border,
    max_height = 0.9,
    min_height = { 10, 0.1 },
    max_width = 0.5,
    min_width = { 0.2, 20 },
    win_opts = {
      cursorline = true,
      winblend = 0, -- no transparency, like every other float here
    },
    autojump = false,
    preview = true, -- code of a symbol without children in the right column
    keymaps = {
      ["<CR>"] = "actions.jump",
      ["<2-LeftMouse>"] = "actions.jump",
      ["<C-v>"] = "actions.jump_vsplit",
      ["<C-s>"] = "actions.jump_split",
      ["h"] = "actions.left",
      ["l"] = "actions.right",
      -- `q` / `<Esc>` close it like every other float; `<C-c>` is not used.
      ["<C-c>"] = false,
      ["q"] = "actions.close",
      ["<Esc>"] = "actions.close",
    },
  },

  lsp = {
    diagnostics_trigger_update = false,
    update_when_errors = true,
    update_delay = 300,
    priority = {},
  },
  treesitter = { update_delay = 300 },
  markdown = { update_delay = 300 },
  asciidoc = { update_delay = 300 },
  man = { update_delay = 300 },
}

return M
