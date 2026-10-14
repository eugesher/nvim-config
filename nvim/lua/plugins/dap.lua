local spec = require("settings").spec

return {
  spec("mfussenegger/nvim-dap", "dap.dap", {
    dependencies = { "theHamsta/nvim-dap-virtual-text" },
  }),
  spec("igorlfs/nvim-dap-view", "dap.dap-view"),
  spec("theHamsta/nvim-dap-virtual-text", "dap.dap-virtual-text"),
}
