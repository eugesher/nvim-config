local icons = require("settings.icons").dap

local M = {}

local function server_path()
  return vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
end
M.server_path = server_path

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
      require("dap").set_breakpoint(nil, nil, message)
    end
  end)
end

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
  { "<leader>db", dap_call("toggle_breakpoint"), desc = "Toggle breakpoint" },
  { "<leader>dB", conditional_breakpoint, desc = "Conditional breakpoint" },
  { "<leader>dp", log_point, desc = "Log point" },
  { "<leader>dx", dap_call("clear_breakpoints"), desc = "Clear all breakpoints" },
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
  { "<leader>du", "<cmd>DapViewToggle<cr>", desc = "Toggle debugger panel" },
  {
    "<leader>dw",
    "<cmd>DapViewWatch<cr>",
    mode = { "n", "x" },
    desc = "Watch expression under cursor",
  },
  { "<leader>dv", "<cmd>DapVirtualTextToggle<cr>", desc = "Toggle inline values" },
}

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

local COMMON = {
  sourceMaps = true,
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
    with_common({
      type = "pwa-node",
      request = "attach",
      name = "Attach: port 9229",
      address = "127.0.0.1",
      port = 9229,
      restart = true,
      cwd = "${workspaceFolder}",
    }),
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

local function open_panel()
  local trouble = package.loaded["trouble"]
  if trouble then
    pcall(trouble.close)
  end
  vim.cmd("DapViewOpen")
end

local function close_panel()
  vim.cmd("DapViewClose!")
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "dap-view-term" and #vim.api.nvim_tabpage_list_wins(0) > 1 then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
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

  dap.adapters["pwa-node"] = {
    type = "server",
    host = "127.0.0.1",
    port = "${port}",
    executable = {
      command = "node",
      args = { server, "${port}", "127.0.0.1" },
    },
  }

  for _, filetype in ipairs({ "typescript", "javascript" }) do
    dap.configurations[filetype] = node_configurations()
  end

  local fallback = dap.defaults.fallback
  fallback.exception_breakpoints = { "uncaught" }
  fallback.focus_terminal = false
  fallback.switchbuf = "usevisible,usetab,uselast"

  dap.listeners.before.launch["settings_dap_panel"] = open_panel
  dap.listeners.before.attach["settings_dap_panel"] = open_panel
  dap.listeners.before.event_terminated["settings_dap_panel"] = close_panel
  dap.listeners.before.event_exited["settings_dap_panel"] = close_panel
end

return M
