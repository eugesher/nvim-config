-- defaults verified against nvim-dap v0.10.0-68-gcfa2d58 (2026-09-12)
--
-- Debug Adapter Protocol client: breakpoints, stepping, stack and variables for
-- Node.js and TypeScript. The adapter is js-debug-adapter (the Mason package of
-- microsoft/vscode-js-debug), configured directly — nvim-dap-vscode-js has been
-- unmaintained since 2022 (decision recorded in task 16). The debugger UI
-- (panels, watches) arrives with task 17.
--
-- nvim-dap has no setup(): everything is assigned in `config`, which lazy.nvim
-- runs on the first <leader>d key.
--
-- `.vscode/launch.json` needs no code here: nvim-dap reads it on every
-- dap.continue() through its built-in `dap.launch.json` config provider.
-- dap.ext.vscode.load_launchjs() is deprecated and only warns.

local icons = require("settings.icons").dap

local M = {}

-- Entry point of the adapter inside the Mason package.
local function server_path()
  return vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
end

local function conditional_breakpoint()
  vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
    if condition and condition ~= "" then
      require("dap").set_breakpoint(condition)
    end
  end)
end

local function log_point()
  vim.ui.input({ prompt = "Log point message: " }, function(message)
    if message and message ~= "" then
      -- Third parameter: the message is logged instead of stopping.
      require("dap").set_breakpoint(nil, nil, message)
    end
  end)
end

-- <leader>da: the attach configuration straight away, without picking from the
-- list that <leader>dc shows.
local function attach_to_process()
  local dap = require("dap")
  local filetype = vim.bo.filetype
  for _, config in ipairs(dap.configurations[filetype] or {}) do
    if config.request == "attach" and config.processId then
      return dap.run(config)
    end
  end
  vim.notify(("dap: no attach configuration for %q"):format(filetype), vim.log.levels.WARN)
end

local function widget(name)
  return function()
    local widgets = require("dap.ui.widgets")
    widgets.centered_float(widgets[name])
  end
end

local function dap_call(method, ...)
  local args = { ... }
  return function()
    require("dap")[method](unpack(args))
  end
end

M.keys = {
  -- Breakpoints.
  { "<leader>db", dap_call("toggle_breakpoint"), desc = "Toggle breakpoint" },
  { "<leader>dB", conditional_breakpoint, desc = "Conditional breakpoint" },
  { "<leader>dp", log_point, desc = "Log point" },
  { "<leader>dx", dap_call("clear_breakpoints"), desc = "Clear all breakpoints" },
  -- Session control. The F-keys are the VS Code ones, as muscle memory.
  { "<leader>dc", dap_call("continue"), desc = "Continue / start" },
  { "<F5>", dap_call("continue"), desc = "Debug: continue / start" },
  { "<leader>do", dap_call("step_over"), desc = "Step over" },
  { "<F10>", dap_call("step_over"), desc = "Debug: step over" },
  { "<leader>di", dap_call("step_into"), desc = "Step into" },
  { "<F11>", dap_call("step_into"), desc = "Debug: step into" },
  { "<leader>dO", dap_call("step_out"), desc = "Step out" },
  { "<S-F11>", dap_call("step_out"), desc = "Debug: step out" },
  { "<leader>dC", dap_call("run_to_cursor"), desc = "Run to cursor" },
  { "<leader>dt", dap_call("terminate"), desc = "Terminate session" },
  { "<S-F5>", dap_call("terminate"), desc = "Debug: terminate session" },
  { "<leader>dl", dap_call("run_last"), desc = "Run last configuration" },
  { "<leader>da", attach_to_process, desc = "Attach to process" },
  -- Inspecting a stopped session.
  { "<leader>dr", dap_call("repl", "toggle"), desc = "Toggle REPL" },
  {
    "<leader>de",
    function()
      require("dap.ui.widgets").hover()
    end,
    mode = { "n", "x" },
    desc = "Evaluate expression",
  },
  { "<leader>dj", dap_call("down"), desc = "Down the stack" },
  { "<leader>dk", dap_call("up"), desc = "Up the stack" },
  { "<leader>df", widget("frames"), desc = "Frames" },
  { "<leader>ds", widget("scopes"), desc = "Scopes" },
}

-- The five signs nvim-dap draws. Colors come from catppuccin's `dap`
-- integration; only the line of the stopped frame needs a group of its own
-- (settings/theme.lua).
local SIGNS = {
  DapBreakpoint = { text = icons.breakpoint, texthl = "DapBreakpoint" },
  DapBreakpointCondition = { text = icons.condition, texthl = "DapBreakpointCondition" },
  DapLogPoint = { text = icons.logpoint, texthl = "DapLogPoint" },
  DapBreakpointRejected = { text = icons.rejected, texthl = "DapBreakpointRejected" },
  DapStopped = {
    text = icons.stopped,
    texthl = "DapStopped",
    linehl = "DapStoppedLine",
    numhl = "DapStopped",
  },
}

-- Fields shared by every configuration below.
local COMMON = {
  sourceMaps = true, -- stop in the .ts file, not in compiled .js
  outFiles = { "${workspaceFolder}/dist/**/*.js", "!**/node_modules/**" },
  skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
  resolveSourceMapLocations = { "${workspaceFolder}/**", "!**/node_modules/**" },
  console = "integratedTerminal",
  protocol = "inspector",
  envFile = "${workspaceFolder}/.env",
}

local function with_common(config)
  return vim.tbl_extend("keep", config, COMMON)
end

local function node_configurations()
  return {
    with_common({
      type = "pwa-node",
      request = "attach",
      name = "Attach: pick process",
      processId = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    }),
    -- `nest start --debug` on this machine. No localRoot / remoteRoot here:
    -- the pair tells js-debug the process runs somewhere else, and against a
    -- local process breakpoints then stay "provisional" and never fire
    -- (verified in task 16 — with the pair no stopped event ever arrives).
    with_common({
      type = "pwa-node",
      request = "attach",
      name = "Attach: port 9229",
      address = "127.0.0.1",
      port = 9229,
      restart = true,
      cwd = "${workspaceFolder}",
    }),
    -- The same port forwarded out of a container. Here the pair is required,
    -- otherwise the container paths the adapter reports match nothing locally.
    -- Inside the container: --inspect=0.0.0.0:9229, port published outside.
    with_common({
      type = "pwa-node",
      request = "attach",
      name = "Attach: port 9229 (Docker)",
      address = "127.0.0.1",
      port = 9229,
      restart = true,
      cwd = "${workspaceFolder}",
      localRoot = "${workspaceFolder}",
      remoteRoot = "/usr/src/app",
    }),
    -- tsconfig-paths/register: NestJS projects resolve `@app/...` aliases
    -- through tsconfig `paths`, and ts-node alone does not.
    with_common({
      type = "pwa-node",
      request = "launch",
      name = "Launch: ts-node current file",
      runtimeExecutable = "npx",
      runtimeArgs = { "ts-node", "-r", "tsconfig-paths/register" },
      program = "${file}",
      cwd = "${workspaceFolder}",
    }),
    with_common({
      type = "pwa-node",
      request = "launch",
      name = "Launch: nest start:debug",
      runtimeExecutable = "npm",
      runtimeArgs = { "run", "start:debug" },
      cwd = "${workspaceFolder}",
    }),
  }
end

function M.config()
  local dap = require("dap")

  dap.set_log_level("WARN")

  for name, sign in pairs(SIGNS) do
    vim.fn.sign_define(name, sign)
  end

  local server = server_path()
  if not vim.uv.fs_stat(server) then
    vim.notify(
      "dap: js-debug-adapter is missing, run :MasonInstall js-debug-adapter\n" .. server,
      vim.log.levels.ERROR
    )
  end

  -- host, port and the two args are all required: without them nvim-dap
  -- cannot start the server and the session dies silently.
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = "${port}", -- nvim-dap picks a free port and substitutes it in `args`
    executable = {
      command = "node",
      args = { server, "${port}", "127.0.0.1" },
    },
  }

  -- Both filetypes get the same list; `.vscode/launch.json` entries are added
  -- by nvim-dap itself on top of these.
  for _, filetype in ipairs({ "typescript", "javascript" }) do
    dap.configurations[filetype] = node_configurations()
  end

  -- Client behaviour (dap.defaults), stated explicitly.
  local fallback = dap.defaults.fallback
  fallback.exception_breakpoints = { "uncaught" }
  fallback.focus_terminal = false -- the debugee's terminal does not steal focus
  fallback.switchbuf = "usevisible,usetab,uselast" -- no jumps within a visible frame
  fallback.terminal_win_cmd = "belowright new"
end

return M
