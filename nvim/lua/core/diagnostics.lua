-- Diagnostics presentation. Applies to every source (LSP, linters, codebook).

local user = require("user.settings")
local severity = vim.diagnostic.severity

local icons = require("settings.icons").diagnostics

vim.diagnostic.config({
  -- Inline text only for WARN and above: INFO/HINT (spelling, unused vars)
  -- would otherwise flood every line; they stay visible as signs/underline.
  virtual_text = {
    prefix = "●",
    spacing = 2,
    severity = { min = severity.WARN },
  },
  virtual_lines = false,
  signs = {
    text = {
      [severity.ERROR] = icons.Error,
      [severity.WARN] = icons.Warn,
      [severity.INFO] = icons.Info,
      [severity.HINT] = icons.Hint,
    },
    numhl = {
      [severity.ERROR] = "DiagnosticSignError",
      [severity.WARN] = "DiagnosticSignWarn",
      [severity.INFO] = "DiagnosticSignInfo",
      [severity.HINT] = "DiagnosticSignHint",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = user.ui.border,
    source = "if_many", -- name the server only when several report here
    header = "",
    prefix = "",
    focusable = true,
  },
  jump = {
    -- Open the float at the diagnostic after `]d`, `]e`, … `on_jump` replaces
    -- `jump.float`, deprecated in 0.12; the body mirrors what `float = true` did.
    on_jump = function(_, bufnr)
      vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
    end,
  },
})
