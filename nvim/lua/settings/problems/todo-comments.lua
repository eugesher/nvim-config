local icons = require("settings.icons")

local M = {}

M.event = { "BufReadPost", "BufNewFile" }

local function jump(direction)
  return function()
    require("todo-comments")["jump_" .. direction]()
  end
end

M.keys = {
  { "]td", jump("next"), desc = "Next todo comment" },
  { "[td", jump("prev"), desc = "Previous todo comment" },
  { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo comments" },
}

local DEFAULT_COLORS = {
  error = { "DiagnosticError", "ErrorMsg", "#DC2626" },
  warning = { "DiagnosticWarn", "WarningMsg", "#FBBF24" },
  info = { "DiagnosticInfo", "#2563EB" },
  hint = { "DiagnosticHint", "#10B981" },
  default = { "Identifier", "#7C3AED" },
  test = { "Identifier", "#FF00FF" },
}

function M.opts()
  local palette = require("settings.ui.theme").palette()
  local colors = DEFAULT_COLORS
  if palette then
    colors = {
      error = { palette.red, "DiagnosticError" },
      warning = { palette.yellow, "DiagnosticWarn" },
      info = { palette.blue, "DiagnosticInfo" },
      hint = { palette.teal, "DiagnosticHint" },
      default = { palette.mauve, "Identifier" },
      test = { palette.pink, "Identifier" },
    }
  end

  return {
    signs = true,
    sign_priority = 8,
    keywords = {
      FIX = {
        icon = icons.todo.fix .. " ",
        color = "error",
        alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
      },
      TODO = { icon = icons.todo.todo .. " ", color = "info" },
      HACK = { icon = icons.todo.hack .. " ", color = "warning" },
      WARN = { icon = icons.todo.warn .. " ", color = "warning", alt = { "WARNING", "XXX" } },
      PERF = {
        icon = icons.todo.perf .. " ",
        color = "default",
        alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" },
      },
      NOTE = { icon = icons.todo.note .. " ", color = "hint", alt = { "INFO" } },
      TEST = {
        icon = icons.todo.test .. " ",
        color = "test",
        alt = { "TESTING", "PASSED", "FAILED" },
      },
    },
    gui_style = {
      fg = "NONE",
      bg = "BOLD",
    },
    merge_keywords = true,
    highlight = {
      multiline = true,
      multiline_pattern = "^.",
      multiline_context = 10,
      before = "",
      keyword = "wide",
      after = "fg",
      pattern = [[.*<(KEYWORDS)\s*:]],
      comments_only = true,
      max_line_len = 400,
      exclude = {},
    },
    colors = colors,
    search = {
      command = "rg",
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
      },
      pattern = [[\b(KEYWORDS):]],
    },
  }
end

return M
