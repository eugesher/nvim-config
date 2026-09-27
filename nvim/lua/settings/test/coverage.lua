local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

local LCOV = "coverage/lcov.info"

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

function M.init()
  vim.api.nvim_create_user_command("CoverageRun", function()
    local command = user.coverage.command
    vim.notify("coverage: running " .. table.concat(command, " "))
    vim.system(command, { cwd = vim.fn.getcwd(), text = true }, function(result)
      vim.schedule(function()
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

local DEFAULT_SIGN_COLORS = { covered = "#B7F071", uncovered = "#F07178", partial = "#AA71F0" }

function M.opts()
  local palette = require("settings.ui.theme").palette()
  local sign_colors = DEFAULT_SIGN_COLORS
  if palette then
    sign_colors = { covered = palette.green, uncovered = palette.red, partial = palette.yellow }
  end
  local bar = icons.coverage.bar

  return {
    commands = true,
    auto_reload = true,
    auto_reload_timeout_ms = 500,
    sign_group = "coverage",
    lcov_file = nil,
    load_coverage_cb = function(ftype)
      vim.notify("coverage: loaded " .. ftype)
    end,

    highlights = {
      covered = { fg = sign_colors.covered },
      uncovered = { fg = sign_colors.uncovered },
      partial = { fg = sign_colors.partial },
      summary_border = { link = "FloatBorder" },
      summary_normal = { link = "NormalFloat" },
      summary_cursor_line = { link = "CursorLine" },
      summary_header = { style = "bold,underline", sp = "fg" },
      summary_pass = { link = "CoverageCovered" },
      summary_fail = { link = "CoverageUncovered" },
    },

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
      min_coverage = 80.0,
    },

    lang = {
      javascript = { coverage_file = LCOV },
      typescript = { coverage_file = LCOV },
    },
  }
end

return M
