local user = require("user.settings")
local severity = vim.diagnostic.severity

local icons = require("settings.icons").diagnostics

require("core.annotations").setup()

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = false,
  ["myconfig/above"] = {
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
