-- Debugger: the DAP client core. The adapter itself (js-debug-adapter, the
-- Mason package of microsoft/vscode-js-debug) is configured directly in
-- settings/dap.lua — nvim-dap-vscode-js is not used (decision recorded in
-- task 16). The debugger UI arrives with task 17.

local spec = require("settings").spec

return {
  spec("mfussenegger/nvim-dap", "dap"),
}
