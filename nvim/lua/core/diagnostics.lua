local user = require("user.settings")
local severity = vim.diagnostic.severity

local icons = require("settings.icons").diagnostics

require("core.annotations").setup()

local unnecessary = vim.lsp.protocol.DiagnosticTag.Unnecessary
local lsp_warning = vim.lsp.protocol.DiagnosticSeverity.Warning

local function raise_unnecessary(diagnostics)
  for _, diagnostic in ipairs(diagnostics or {}) do
    local tagged = diagnostic.tags and vim.tbl_contains(diagnostic.tags, unnecessary)
    if tagged and (diagnostic.severity or lsp_warning) > lsp_warning then
      diagnostic.severity = lsp_warning
    end
  end
end

local function raise_in_handler(method, raise)
  local handler = vim.lsp.handlers[method]
  vim.lsp.handlers[method] = function(err, result, ctx, config)
    if result then
      raise(result)
    end
    return handler(err, result, ctx, config)
  end
end

raise_in_handler("textDocument/publishDiagnostics", function(result)
  raise_unnecessary(result.diagnostics)
end)

raise_in_handler("textDocument/diagnostic", function(result)
  raise_unnecessary(result.items)
  for _, related in pairs(result.relatedDocuments or {}) do
    raise_unnecessary(related.items)
  end
end)

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = false,
  ["myconfig/annotations"] = {
    severity = { min = severity.HINT },
  },
  signs = {
    text = {
      [severity.ERROR] = icons.Error,
      [severity.WARN] = icons.Warn,
      [severity.INFO] = icons.Info,
      [severity.HINT] = icons.Hint,
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = user.ui.border,
    source = "if_many",
    header = "",
    prefix = "",
    focusable = true,
  },
  jump = {
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
    end,
  },
})
