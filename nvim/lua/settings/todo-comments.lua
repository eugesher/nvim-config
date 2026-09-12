-- defaults verified against todo-comments.nvim v1.5.0 (2026-09-12)
--
-- Highlights TODO / FIX / HACK / … comments and collects them project-wide.
-- The list opens in the problems panel (`:Trouble todo`, <leader>xt): the source
-- ships with this plugin, so the key loads it and trouble picks the mode up.
--
-- Searching needs ripgrep; without it the highlighting still works and only the
-- project-wide list stays empty.

local icons = require("settings.icons")

local M = {}

-- Highlighting has to be in place before the first file is on screen.
M.event = { "BufReadPost", "BufNewFile" }

local function jump(direction)
  return function()
    require("todo-comments")["jump_" .. direction]()
  end
end

-- `]td` / `[td`, not `]t` / `[t`: those belong to neotest. The longer sequence
-- costs one 'timeoutlen' after `]t`.
M.keys = {
  { "]td", jump("next"), desc = "Next todo comment" },
  { "[td", jump("prev"), desc = "Previous todo comment" },
  { "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo comments" },
}

function M.opts()
  -- The palette, not hex literals: with a different flavor the keyword colors
  -- have to keep their contrast against the new background (settings/theme.lua).
  local ok, palettes = pcall(require, "catppuccin.palettes")
  local colors = ok and palettes.get_palette() or {}

  return {
    signs = true, -- keyword icon in the sign column
    -- Above gitsigns (6) and coverage (5): a TODO marks the line itself.
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
      fg = "NONE", -- the text after the keyword
      bg = "BOLD", -- the keyword itself, on a colored background
    },
    merge_keywords = true, -- the list above replaces nothing, it is the default set
    highlight = {
      multiline = true,
      multiline_pattern = "^.",
      multiline_context = 10,
      before = "", -- the comment characters stay in their own color
      keyword = "wide", -- colored background around the keyword
      after = "fg", -- the rest of the line takes the keyword color
      pattern = [[.*<(KEYWORDS)\s*:]], -- vim regex, `TODO:` with optional spaces
      comments_only = true, -- treesitter: `TODO:` inside a string is not a todo
      max_line_len = 400,
      exclude = {},
    },
    -- Hex from the palette comes first, so the colors do not depend on which
    -- diagnostic groups happen to be defined when the plugin loads.
    colors = {
      error = { colors.red, "DiagnosticError" },
      warning = { colors.yellow, "DiagnosticWarn" },
      info = { colors.blue, "DiagnosticInfo" },
      hint = { colors.teal, "DiagnosticHint" },
      default = { colors.mauve, "Identifier" },
      test = { colors.pink, "Identifier" },
    },
    search = {
      command = "rg",
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
      },
      pattern = [[\b(KEYWORDS):]], -- ripgrep regex
    },
  }
end

return M
