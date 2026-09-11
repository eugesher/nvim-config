-- glyphs verified against Nerd Fonts v3 (2026-09-11)
--
-- Single source of glyphs for the whole config. Pure data: raw glyphs without
-- padding — consumers add spacing where their layout needs it. Nerd Fonts v3
-- only (the v2 Material Design range U+F500–U+FD46 was removed upstream).

local M = {}

-- Diagnostic severities (signs, status line, bufferline, trouble).
M.diagnostics = {
  Error = "",
  Warn = "",
  Info = "",
  Hint = "",
}

-- Git change types and file states (status line diff, file tree, gitsigns).
M.git = {
  added = "",
  modified = "",
  removed = "",
  untracked = "",
  staged = "",
  renamed = "󰁕",
  ignored = "",
  unstaged = "󰄱",
  conflict = "",
}

-- LSP kinds: the full CompletionItemKind set (blink.cmp) followed by the
-- SymbolKind names it lacks (aerial, dropbar).
M.kinds = {
  Text = "󰉿",
  Method = "󰊕",
  Function = "󰊕",
  Constructor = "󰒓",
  Field = "󰜢",
  Variable = "󰆦",
  Class = "󱡠",
  Interface = "󱡠",
  Module = "󰅩",
  Property = "󰖷",
  Unit = "󰪚",
  Value = "󰦨",
  Enum = "󰦨",
  Keyword = "󰻾",
  Snippet = "󱄽",
  Color = "󰏘",
  File = "󰈔",
  Reference = "󰬲",
  Folder = "󰉋",
  EnumMember = "󰦨",
  Constant = "󰏿",
  Struct = "󱡠",
  Event = "󱐋",
  Operator = "󰪚",
  TypeParameter = "󰬛",
  Namespace = "󰦮",
  Package = "",
  String = "",
  Number = "󰎠",
  Boolean = "󰨙",
  Array = "󰅪",
  Object = "",
  Key = "󰌋",
  Null = "󰟢",
}

-- Debugger signs (nvim-dap).
M.dap = {
  breakpoint = "",
  condition = "",
  logpoint = "",
  stopped = "󰁕",
  rejected = "",
}

-- Test results (neotest).
M.test = {
  passed = "",
  failed = "",
  running = "",
  skipped = "",
}

-- Generic UI glyphs.
M.ui = {
  chevron_right = "",
  chevron_down = "",
  folder_closed = "",
  folder_open = "",
  folder_empty = "󰉖",
  folder_empty_open = "󰷏",
  file = "",
  close = "",
  arrow_left = "",
  arrow_right = "",
  dot = "●",
  lock = "",
}

-- Keymap namespaces (which-key group icons; colors live in settings/whichkey.lua).
M.keymap_groups = {
  buffers = "󰈔",
  code = "",
  debug = "󰃤",
  database = "",
  find = "",
  git = "",
  hunks = "",
  git_toggles = "",
  lsp = "",
  multicursor = "",
  refactor = "",
  session = "",
  test = "",
  coverage = "",
  ui = "󰙵",
  problems = "󱖫",
  http = "",
  next = "",
  prev = "",
}

-- Package states (Mason UI). Plain Unicode, carried over from the old config.
M.packages = {
  installed = "✓",
  pending = "➜",
  uninstalled = "✗",
}

return M
