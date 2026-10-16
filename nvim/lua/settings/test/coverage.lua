local trust = require("core.trust")
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

local function load_report(place)
  if not vim.uv.fs_stat(report_path()) then
    vim.notify(
      ("coverage: %s not found — run :CoverageRun first"):format(LCOV),
      vim.log.levels.WARN
    )
    return
  end
  require("coverage").load_lcov(report_path(), place)
end

M.keys = {
  { "<leader>tcc", "<cmd>CoverageToggle<cr>", desc = "Toggle coverage signs" },
  {
    "<leader>tcl",
    function()
      load_report(true)
    end,
    desc = "Load and show coverage",
  },
  { "<leader>tcs", "<cmd>CoverageSummary<cr>", desc = "Coverage summary" },
  { "<leader>tcx", "<cmd>CoverageClear<cr>", desc = "Clear coverage" },
  { "<leader>tcr", "<cmd>CoverageRun<cr>", desc = "Run tests with coverage" },
}

local function mtime(path)
  local stat = vim.uv.fs_stat(path)
  return stat and ("%d:%d"):format(stat.mtime.sec, stat.mtime.nsec)
end

function M.init()
  vim.api.nvim_create_user_command("CoverageRun", function()
    local command = user.coverage.command
    local cwd = vim.fn.getcwd()
    if not vim.uv.fs_stat(vim.fs.joinpath(cwd, "package.json")) then
      vim.notify(
        ("coverage: no package.json in %s — run :CoverageRun from the project root"):format(cwd),
        vim.log.levels.WARN
      )
      return
    end
    local dirs = trust.parents(cwd, { "package.json", ".npmrc", "node_modules" })
    dirs[#dirs + 1] = cwd
    for _, dir in ipairs(dirs) do
      if not trust.allowed(dir) then
        vim.notify(
          ("coverage: not run, %s is not trusted (:ProjectTrust)"):format(dir),
          vim.log.levels.WARN
        )
        return
      end
    end
    local report = vim.fs.joinpath(cwd, LCOV)
    local before = mtime(report)
    vim.notify("coverage: running " .. table.concat(command, " "))
    vim.system(command, { cwd = cwd, text = true }, function(result)
      vim.schedule(function()
        if result.signal ~= 0 then
          vim.notify(
            ("coverage: %s was killed by signal %d; report not loaded"):format(
              table.concat(command, " "),
              result.signal
            ),
            vim.log.levels.ERROR
          )
          return
        end
        local after = mtime(report)
        if not after or after == before then
          vim.notify(
            ("coverage: %s wrote no new %s (exit %d)\n%s"):format(
              table.concat(command, " "),
              LCOV,
              result.code,
              vim.trim((result.stderr or ""):sub(-400))
            ),
            vim.log.levels.ERROR
          )
          return
        end
        if result.code ~= 0 then
          vim.notify(
            ("coverage: %s exited %d; showing the report it wrote"):format(
              table.concat(command, " "),
              result.code
            ),
            vim.log.levels.WARN
          )
        end
        if vim.fn.getcwd() ~= cwd then
          vim.notify(
            ("coverage: the working directory changed; :Coverage in %s shows the report"):format(
              cwd
            ),
            vim.log.levels.WARN
          )
          return
        end
        load_report(true)
      end)
    end)
  end, { desc = "Run the project's coverage command, then show the report" })
end

function M.config(_, opts)
  local coverage = require("coverage")
  coverage.setup(opts)
  coverage.load = load_report
  vim.api.nvim_create_user_command("Coverage", function()
    load_report(true)
  end, { desc = "Load the lcov report and show it" })
  vim.api.nvim_create_user_command("CoverageLoad", function()
    load_report(false)
  end, { desc = "Load the lcov report" })
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
