-- defaults verified against oil.nvim v2.16.0-8-gb73018b (2026-09-12)
--
-- A directory as an editable buffer: rename, move, create and delete files by
-- editing lines, applied on `:w`. Renames go through LSP
-- `workspace/willRenameFiles`, so vtsls fixes imports in other files.
-- Directories themselves open in neo-tree (settings/neotree.lua).

local user = require("user.settings")

local M = {}

M.cmd = "Oil"

M.keys = {
  {
    "-",
    function()
      require("oil").open()
    end,
    desc = "Parent directory (oil)",
  },
}

-- Entries never listed, even with hidden files shown (`g.`).
local ALWAYS_HIDDEN = { [".git"] = true, ["node_modules"] = true }

M.opts = {
  -- Must stay false: otherwise oil takes over directory buffers and `nvim .`
  -- opens oil instead of neo-tree.
  default_file_explorer = false,
  columns = { "icon" },
  buf_options = {
    buflisted = false,
    bufhidden = "hide",
  },
  win_options = {
    wrap = false,
    signcolumn = "no",
    cursorcolumn = false,
    foldcolumn = "0",
    spell = false,
    list = false,
    conceallevel = 3,
    concealcursor = "nvic",
  },
  -- FreeDesktop trash on Linux; browse it with `g\`.
  delete_to_trash = true,
  skip_confirm_for_simple_edits = false,
  prompt_save_on_select_new_entry = true,
  cleanup_delay_ms = 2000,
  lsp_file_methods = {
    enabled = true,
    timeout_ms = 1000,
    -- Save the buffers the language server edited (e.g. fixed imports).
    autosave_changes = true,
  },
  constrain_cursor = "editable",
  watch_for_changes = true,
  -- Defaults minus GUI combos (<C-s> split, <C-c> close) and the window
  -- navigation keys <C-h>/<C-l> (core/keymaps.lua), which stay global here.
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    ["<localleader>v"] = { "actions.select", opts = { vertical = true }, mode = "n" },
    ["<localleader>s"] = { "actions.select", opts = { horizontal = true }, mode = "n" },
    ["<localleader>t"] = { "actions.select", opts = { tab = true }, mode = "n" },
    ["<C-p>"] = "actions.preview",
    ["gq"] = { "actions.close", mode = "n" },
    ["gR"] = { "actions.refresh", mode = "n" },
    ["-"] = { "actions.parent", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },
    ["`"] = { "actions.cd", mode = "n" },
    ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
  use_default_keymaps = false,
  view_options = {
    show_hidden = true,
    is_hidden_file = function(name)
      return vim.startswith(name, ".")
    end,
    is_always_hidden = function(name)
      return ALWAYS_HIDDEN[name] == true
    end,
    natural_order = "fast",
    -- Same order as the tree (neo-tree `sort_case_insensitive`).
    case_insensitive = true,
    sort = {
      { "type", "asc" },
      { "name", "asc" },
    },
    highlight_filename = function()
      return nil
    end,
  },
  extra_scp_args = {},
  extra_s3_args = {},
  -- Experimental: git add/mv/rm alongside file operations. Off — git is done by hand.
  git = {
    add = function()
      return false
    end,
    mv = function()
      return false
    end,
    rm = function()
      return false
    end,
  },
  float = {
    padding = 2,
    max_width = 0,
    max_height = 0,
    border = user.ui.border,
    win_options = { winblend = 0 },
    preview_split = "auto",
    override = function(conf)
      return conf
    end,
  },
  preview_win = {
    update_on_cursor_moved = true,
    preview_method = "fast_scratch",
    disable_preview = function()
      return false
    end,
    win_options = {},
  },
  confirmation = {
    max_width = 0.9,
    min_width = { 40, 0.4 },
    max_height = 0.9,
    min_height = { 5, 0.1 },
    border = user.ui.border,
    win_options = { winblend = 0 },
  },
  progress = {
    max_width = 0.9,
    min_width = { 40, 0.4 },
    max_height = { 10, 0.9 },
    min_height = { 5, 0.1 },
    border = user.ui.border,
    minimized_border = "none",
    win_options = { winblend = 0 },
  },
  ssh = { border = user.ui.border },
  keymaps_help = { border = user.ui.border },
}

return M
