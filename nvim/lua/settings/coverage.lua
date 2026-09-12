-- defaults verified against nvim-coverage @a939e42 (2026-09-12)
--
-- Coverage bars in the sign column and a per-file summary: neotest runs tests
-- but does not read coverage reports, so this is a separate plugin (task 19).
-- For JS/TS the report is lcov — `coverage/lcov.info`, written by
-- `npx jest --coverage --coverageReporters=lcov`, by `npm run test:cov`, or by
-- the :CoverageRun command below.

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

local LCOV = "coverage/lcov.info"

-- The summary window is a plenary popup: it takes the border characters
-- themselves, not a style name like 'winborder' does.
local BORDER_CHARS = {
  rounded = { topleft = "╭", topright = "╮", botleft = "╰", botright = "╯" },
  single = { topleft = "┌", topright = "┐", botleft = "└", botright = "┘" },
  double = { topleft = "╔", topright = "╗", botleft = "╚", botright = "╝" },
  solid = { topleft = " ", topright = " ", botleft = " ", botright = " " },
}

local function summary_borders()
  local corners = BORDER_CHARS[user.ui.border] or BORDER_CHARS.rounded
  return vim.tbl_extend("force", {
    top = "─",
    bot = "─",
    left = "│",
    right = "│",
    highlight = "Normal:CoverageSummaryBorder",
  }, corners)
end

M.cmd = {
  "Coverage",
  "CoverageLoad",
  "CoverageLoadLcov",
  "CoverageShow",
  "CoverageHide",
  "CoverageToggle",
  "CoverageClear",
  "CoverageSummary",
}

local function report_path()
  return vim.fs.joinpath(vim.fn.getcwd(), LCOV)
end

-- :Coverage, not :CoverageLoad — the latter reads the report without placing
-- the signs, and after a test run the result should be on screen right away.
-- Without a report the plugin loads nothing and says nothing, so the missing
-- file is reported here instead.
local function load_report()
  if not vim.uv.fs_stat(report_path()) then
    vim.notify(
      ("coverage: %s not found — run :CoverageRun first"):format(LCOV),
      vim.log.levels.WARN
    )
    return
  end
  vim.cmd("Coverage")
end

M.keys = {
  { "<leader>tcc", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage signs" },
  { "<leader>tcl", load_report, desc = "Load and show coverage" },
  { "<leader>tcs", "<cmd>CoverageSummary<cr>", desc = "Coverage summary" },
  { "<leader>tcx", "<cmd>CoverageClear<cr>", desc = "Clear coverage" },
  { "<leader>tcr", "<cmd>CoverageRun<cr>", desc = "Run tests with coverage" },
}

-- :CoverageRun is ours, not the plugin's, so it is created eagerly — it has to
-- exist before the plugin is loaded.
function M.init()
  vim.api.nvim_create_user_command("CoverageRun", function()
    local command = user.coverage.command
    vim.notify("coverage: running " .. table.concat(command, " "))
    vim.system(command, { cwd = vim.fn.getcwd(), text = true }, function(result)
      vim.schedule(function()
        -- Failing tests still produce a report; only a missing report is an error.
        if not vim.uv.fs_stat(report_path()) then
          vim.notify(
            ("coverage: %s produced no %s (exit %d)\n%s"):format(
              table.concat(command, " "),
              LCOV,
              result.code,
              vim.trim((result.stderr or ""):sub(-400))
            ),
            vim.log.levels.ERROR
          )
          return
        end
        load_report()
      end)
    end)
  end, { desc = "Run the project's coverage command, then show the report" })
end

function M.opts()
  -- Colours from the active catppuccin flavour: hard-coded hex values would
  -- become unreadable as soon as the flavour changes (settings/theme.lua).
  local ok, palettes = pcall(require, "catppuccin.palettes")
  local colors = ok and palettes.get_palette() or {}
  local bar = icons.coverage.bar

  return {
    commands = true, -- :Coverage, :CoverageLoad, :CoverageSummary, …
    auto_reload = true, -- watch the report after loading it
    auto_reload_timeout_ms = 500,
    sign_group = "coverage",
    lcov_file = nil, -- :CoverageLoadLcov without an argument reads this
    load_coverage_cb = function(ftype)
      vim.notify("coverage: loaded " .. ftype)
    end,

    highlights = {
      covered = { fg = colors.green },
      uncovered = { fg = colors.red },
      partial = { fg = colors.yellow },
      summary_border = { link = "FloatBorder" },
      summary_normal = { link = "NormalFloat" },
      summary_cursor_line = { link = "CursorLine" },
      summary_header = { style = "bold,underline", sp = "fg" },
      summary_pass = { link = "CoverageCovered" },
      summary_fail = { link = "CoverageUncovered" },
    },

    -- Priority below gitsigns' 6 (settings/gitsigns.lua): 'signcolumn' is one
    -- column wide, so the higher priority would hide the git signs on changed
    -- lines. The plugin's own default is 10.
    signs = {
      covered = { hl = "CoverageCovered", text = bar, priority = 5 },
      uncovered = { hl = "CoverageUncovered", text = bar, priority = 5 },
      partial = { hl = "CoveragePartial", text = bar, priority = 5 },
    },

    summary = {
      width_percentage = 0.7,
      height_percentage = 0.7,
      borders = summary_borders(),
      window = {},
      -- Colour only: nothing is blocked below this percentage.
      min_coverage = 80.0,
    },

    lang = {
      javascript = { coverage_file = LCOV },
      typescript = { coverage_file = LCOV },
    },
  }
end

return M
