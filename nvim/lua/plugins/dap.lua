-- Debugger: the DAP client core, its UI panel and inline variable values.
-- The adapter itself (js-debug-adapter, the Mason package of
-- microsoft/vscode-js-debug) is configured directly in settings/dap/dap.lua —
-- nvim-dap-vscode-js is not used. Neither is nvim-dap-ui: dap-view is lighter
-- and does not rearrange windows.

local spec = require("settings").spec

return {
  -- Virtual text hooks into dap's own listeners, so it loads with dap itself.
  spec("mfussenegger/nvim-dap", "dap.dap", {
    dependencies = { "theHamsta/nvim-dap-virtual-text" },
  }),
  -- The panel opens from the session listeners (settings/dap/dap.lua) and from
  -- <leader>du; lazy.nvim loads it on the first require.
  spec("igorlfs/nvim-dap-view", "dap.dap-view"),
  spec("theHamsta/nvim-dap-virtual-text", "dap.dap-virtual-text"),
}
