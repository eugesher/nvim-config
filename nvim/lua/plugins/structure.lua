local spec = require("settings").spec

return {
  spec("stevearc/aerial.nvim", "structure.aerial", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  spec("Bekaboo/dropbar.nvim", "structure.dropbar", {
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-telescope/telescope-fzf-native.nvim" },
  }),
  spec("nvim-telescope/telescope-fzf-native.nvim", nil, { build = "make" }),
}
