-- Project tree (neo-tree) and directory-as-a-buffer file operations (oil).

local spec = require("settings").spec

return {
  spec("nvim-neo-tree/neo-tree.nvim", "explorer.neotree", {
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
  }),
  -- No settings: libraries loaded on require by neo-tree.
  spec("nvim-lua/plenary.nvim"),
  spec("MunifTanjim/nui.nvim"),
  spec("stevearc/oil.nvim", "explorer.oil", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
}
