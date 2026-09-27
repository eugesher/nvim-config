local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

local JEST_CONFIGS = { "jest.config.ts", "jest.config.js", "jest.config.mjs", "jest.config.cjs" }
local VITEST_CONFIGS =
  { "vitest.config.ts", "vitest.config.js", "vite.config.ts", "vite.config.js" }

local function nearest(names, start)
  local found = vim.fs.find(names, {
    upward = true,
    path = vim.fs.dirname(start ~= "" and start or vim.fn.getcwd()),
    type = "file",
  })[1]
  return found
end

local function jest_adapter()
  return require("neotest-jest")({
    jestCommand = "npx jest",
    jestConfigFile = function(file)
      return nearest(JEST_CONFIGS, file) or "jest.config.js"
    end,
    cwd = function(file)
      local package_json = nearest({ "package.json" }, file)
      return package_json and vim.fs.dirname(package_json) or vim.fn.getcwd()
    end,
    env = { CI = true },
    jest_test_discovery = false,
  })
end

local function vitest_adapter()
  return require("neotest-vitest")({
    vitestCommand = "npx vitest",
    vitestConfigFile = function(file)
      return nearest(VITEST_CONFIGS, file)
    end,
    filter_dir = function(name)
      return name ~= "node_modules" and name ~= "dist" and name ~= "coverage"
    end,
  })
end

local function run(method, ...)
  local args = { ... }
  return function()
    require("neotest").run[method](unpack(args))
  end
end

M.keys = {
  { "<leader>tt", run("run"), desc = "Run nearest test" },
  {
    "<leader>tf",
    function()
      require("neotest").run.run(vim.fn.expand("%"))
    end,
    desc = "Run tests in file",
  },
  {
    "<leader>ta",
    function()
      require("neotest").run.run(vim.fn.getcwd())
    end,
    desc = "Run all tests",
  },
  { "<leader>tl", run("run_last"), desc = "Run last test" },
  {
    "<leader>td",
    function()
      require("neotest").run.run({ strategy = "dap" })
    end,
    desc = "Debug nearest test",
  },
  { "<leader>tS", run("stop"), desc = "Stop test run" },
  {
    "<leader>ts",
    function()
      require("neotest").summary.toggle()
    end,
    desc = "Toggle test tree",
  },
  {
    "<leader>to",
    function()
      require("neotest").output.open({ enter = true, auto_close = true })
    end,
    desc = "Show test output",
  },
  {
    "<leader>tO",
    function()
      require("neotest").output_panel.toggle()
    end,
    desc = "Toggle output panel",
  },
  {
    "<leader>tw",
    function()
      require("neotest").watch.toggle(vim.fn.expand("%"))
    end,
    desc = "Toggle watch for file",
  },
  {
    "<leader>tW",
    function()
      require("neotest").watch.toggle(vim.fn.getcwd())
    end,
    desc = "Toggle watch for project",
  },
  {
    "]t",
    function()
      require("neotest").jump.next({ status = "failed" })
    end,
    desc = "Next failed test",
  },
  {
    "[t",
    function()
      require("neotest").jump.prev({ status = "failed" })
    end,
    desc = "Previous failed test",
  },
}

function M.opts()
  return {
    adapters = { jest_adapter(), vitest_adapter() },

    discovery = { enabled = false, concurrent = 1 },
    running = { concurrent = true },
    run = { enabled = true },
    default_strategy = "integrated",

    summary = {
      enabled = true,
      animated = true,
      follow = true,
      expand_errors = true,
      count = true,
      open = "botright vsplit | vertical resize 50",
      mappings = {
        attach = "a",
        clear_marked = "M",
        clear_target = "T",
        debug = "d",
        debug_marked = "D",
        expand = { "<CR>", "<2-LeftMouse>" },
        expand_all = "e",
        help = "?",
        jumpto = "i",
        mark = "m",
        next_failed = "J",
        next_sibling = ">",
        output = "o",
        parent = "P",
        prev_failed = "K",
        prev_sibling = "<",
        run = "r",
        run_marked = "R",
        short = "O",
        stop = "u",
        target = "t",
        watch = "w",
      },
    },

    output = { enabled = true, open_on_run = false },
    output_panel = { enabled = true, open = "botright split | resize " .. user.ui.panel_height },
    quickfix = { enabled = false, open = false },
    status = { enabled = true, signs = true, virtual_text = false },
    state = { enabled = true },
    benchmark = { enabled = true },
    jump = { enabled = true },

    icons = {
      passed = icons.test.passed,
      failed = icons.test.failed,
      running = icons.test.running,
      skipped = icons.test.skipped,
    },

    diagnostic = { enabled = true, severity = vim.diagnostic.severity.ERROR },
    floating = {
      border = user.ui.border,
      max_height = 0.8,
      max_width = 0.8,
      options = {},
    },
    strategies = { integrated = { height = 40, width = 120 } },
    watch = { enabled = true },

    projects = {},
    consumers = {},
    log_level = vim.log.levels.WARN,
  }
end

return M
