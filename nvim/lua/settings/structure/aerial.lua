local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

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

local function kind_icons()
  local padded = {}
  for kind, glyph in pairs(icons.kinds) do
    padded[kind] = glyph .. " "
  end
  return padded
end

local function on_attach(bufnr)
  local aerial = require("aerial")
  vim.keymap.set("n", "{", function()
    aerial.prev(vim.v.count1)
  end, { buffer = bufnr, desc = "Previous symbol" })
  vim.keymap.set("n", "}", function()
    aerial.next(vim.v.count1)
  end, { buffer = bufnr, desc = "Next symbol" })
end

local function post_parse_symbol(_, item, ctx)
  return not (
    ctx.backend_name == "lsp"
    and item.kind == "Function"
    and item.name:match(" callback$")
  )
end

M.opts = {
  backends = { "lsp", "treesitter", "markdown", "man" },

  layout = {
    max_width = { 40, 0.3 },
    width = nil,
    min_width = 28,
    win_opts = {},
    default_direction = "prefer_right",
    placement = "edge",
    resize_to_content = true,
    preserve_equality = false,
  },

  attach_mode = "window",
  close_automatic_events = {},

  keymaps = {
    ["?"] = "actions.show_help",
    ["g?"] = "actions.show_help",
    ["<CR>"] = "actions.jump",
    ["<2-LeftMouse>"] = "actions.jump",
    ["<C-v>"] = "actions.jump_vsplit",
    ["<C-s>"] = "actions.jump_split",
    ["p"] = "actions.scroll",
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

  lazy_load = false,
  disable_max_lines = 10000,
  disable_max_size = 2000000,

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
  highlight_on_hover = true,
  highlight_on_jump = 300,
  autojump = false,

  icons = kind_icons(),

  ignore = {
    unlisted_buffers = false,
    diff_windows = true,
    filetypes = {},
    buftypes = "special",
    wintypes = "special",
  },

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
  get_highlight = function(_, _, _) end,

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
      winblend = 0,
    },
    autojump = false,
    preview = true,
    keymaps = {
      ["<CR>"] = "actions.jump",
      ["<2-LeftMouse>"] = "actions.jump",
      ["<C-v>"] = "actions.jump_vsplit",
      ["<C-s>"] = "actions.jump_split",
      ["h"] = "actions.left",
      ["l"] = "actions.right",
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
