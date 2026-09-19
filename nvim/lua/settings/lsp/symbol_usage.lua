local user = require("user.settings")

local kinds = vim.lsp.protocol.SymbolKind

local M = {}

local globs = {}

local function ignored_file(bufnr, patterns)
  local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
  for _, pattern in ipairs(patterns) do
    if not globs[pattern] then
      globs[pattern] = vim.glob.to_lpeg(pattern)
    end
    if globs[pattern]:match(name) then
      return true
    end
  end
  return false
end

local function module_or_class_scope(data)
  local parent = data.parent.kind
  return parent ~= kinds.Function and parent ~= kinds.Method and parent ~= kinds.Constructor
end

local function tracked_field(data)
  local parent = data.parent.kind
  return (parent == kinds.Class or parent == kinds.Interface)
    and not ignored_file(data.bufnr, user.lsp.unused_skip.fields)
end

local function tracked_method(data)
  return not ignored_file(data.bufnr, user.lsp.unused_skip.methods)
end

local javascript = {
  kinds = {
    kinds.Class,
    kinds.Enum,
    kinds.Function,
    kinds.Interface,
    kinds.Method,
    kinds.Property,
    kinds.Variable,
  },
  kinds_filter = {
    [kinds.Constant] = { module_or_class_scope },
    [kinds.Method] = { tracked_method },
    [kinds.Property] = { tracked_field },
    [kinds.Variable] = { module_or_class_scope },
  },
}

M.cond = user.lsp.unused_symbols
M.event = "LspAttach"

M.opts = {
  hl = { link = "SymbolUsageUnused" },
  kinds = { kinds.Function, kinds.Method },
  kinds_filter = {},
  vt_position = "end_of_line",
  request_pending_text = false,
  text_format = function(symbol)
    return symbol.references == 0 and "unused" or ""
  end,
  references = { enabled = true, include_declaration = false },
  definition = { enabled = false },
  implementation = { enabled = false },
  disable = { lsp = {}, filetypes = {}, cond = {} },
  filetypes = {
    javascript = javascript,
    javascriptreact = javascript,
    typescript = javascript,
    typescriptreact = javascript,
  },
  symbol_request_pos = "end",
  log = { enabled = false },
}

M.keys = {
  {
    "<leader>uu",
    function()
      require("symbol-usage").toggle()
    end,
    desc = "Toggle unused markers",
  },
}

return M
