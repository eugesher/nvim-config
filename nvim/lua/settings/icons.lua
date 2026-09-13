local M = {}

M.diagnostics = {
  Error = "",
  Warn = "",
  Info = "",
  Hint = "",
}

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

M.git_signs = {
  add = "█",
  change = "█",
  delete = "▄",
  topdelete = "▀",
  changedelete = "▒",
  untracked = "",
}

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

M.dap = {
  breakpoint = "",
  condition = "",
  logpoint = "",
  stopped = "󰁕",
  rejected = "",
}

M.test = {
  passed = "",
  failed = "",
  running = "",
  skipped = "",
}

M.database = {
  db = "󰆼",
  buffers = "",
  saved_queries = "",
  schemas = "",
  schema = "󰙅",
  tables = "󰓱",
  table = "",
  helper = "󰓫",
  buffer = "",
  saved_query = "",
  new_query = "󰓰",
  add_connection = "󰆺",
  connection_ok = "✓",
  connection_error = "✕",
}

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
  check = "✓",
}

M.coverage = {
  bar = "▎",
}

M.todo = {
  fix = "",
  todo = "",
  hack = "",
  warn = "",
  perf = "",
  note = "",
  test = "⏲",
}

M.keymap_groups = {
  buffers = "󰈔",
  code = "",
  debug = "󰃤",
  database = "",
  find = "",
  git = "",
  hunks = "",
  git_toggles = "",
  conflicts = "",
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

M.packages = {
  installed = "✓",
  pending = "➜",
  uninstalled = "✗",
}

return M
