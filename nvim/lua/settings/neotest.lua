-- defaults verified against neotest v5.20.0-1-g27bf921, neotest-jest @0e7979d
-- and neotest-vitest v0.2.0-35-gc3c6971 (2026-09-12)
--
-- Test panel: a tree of tests, per-test statuses in the sign column, failures
-- as diagnostics, watch mode and debugging a test through nvim-dap (task 16).
-- vim-test is not used (decision recorded in task 18).
--
-- Both adapters are registered at once; neotest asks each one whether it
-- recognises the project, so a Jest repo and a Vitest repo both work.

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

local JEST_CONFIGS = { "jest.config.ts", "jest.config.js", "jest.config.mjs", "jest.config.cjs" }
local VITEST_CONFIGS =
  { "vitest.config.ts", "vitest.config.js", "vite.config.ts", "vite.config.js" }

-- Nearest file from `names`, searching upwards from `start`; the project root
-- of a monorepo package rather than the workspace root.
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
    -- npx resolves the project's own jest. No trailing `--`: the adapter
    -- appends --json / --outputFile / --testLocationInResults itself, and
    -- after a `--` jest would take them as path patterns — the results file
    -- is then never written and every test comes back "failed" (task 18).
    jestCommand = "npx jest",
    -- In a monorepo the config sits next to the package, not at the root.
    jestConfigFile = function(file)
      return nearest(JEST_CONFIGS, file) or "jest.config.js"
    end,
    -- Same reasoning: run from the package root, so `rootDir` and module
    -- resolution match what `npm test` would do in that package.
    cwd = function(file)
      local package_json = nearest({ "package.json" }, file)
      return package_json and vim.fs.dirname(package_json) or vim.fn.getcwd()
    end,
    env = { CI = true }, -- no watch mode, no coloured output
    -- Discovery of `it.each` tables runs jest once per file; off for speed.
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

-- A function: the adapters have to be required, and that must not happen while
-- the spec is being built.
function M.opts()
  return {
    adapters = { jest_adapter(), vitest_adapter() },

    -- The single most important setting here. Automatic discovery walks the
    -- whole workspace, which freezes the editor in a NestJS monorepo; the tree
    -- is built from the files you open and from what you run.
    discovery = { enabled = false, concurrent = 1 },
    running = { concurrent = true },
    run = { enabled = true },
    default_strategy = "integrated",

    summary = {
      enabled = true,
      animated = true,
      follow = true, -- the tree follows the cursor between files
      expand_errors = true,
      count = true,
      open = "botright vsplit | vertical resize 50",
      -- Keys inside the tree, the plugin's defaults stated in full.
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

    output = { enabled = true, open_on_run = false }, -- <leader>to opens it
    -- Same height as the debugger panel and the problems list: they share the
    -- bottom split (user/settings.lua).
    output_panel = { enabled = true, open = "botright split | resize " .. user.ui.panel_height },
    -- Failures are shown as diagnostics in the buffer, the quickfix list stays
    -- free for grep and LSP results.
    quickfix = { enabled = false, open = false },
    status = { enabled = true, signs = true, virtual_text = false },
    state = { enabled = true }, -- the status line component reads this (settings/lualine.lua)
    benchmark = { enabled = true },
    jump = { enabled = true },

    -- Statuses come from the shared glyph set; the box-drawing icons of the
    -- tree stay as the plugin ships them.
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
    -- `symbol_queries` keeps the plugin's per-language treesitter queries
    -- (typescript, tsx and javascript among them): they tell watch mode which
    -- files a test depends on.
    watch = { enabled = true },

    projects = {},
    consumers = {},
    log_level = vim.log.levels.WARN,
  }
end

return M
