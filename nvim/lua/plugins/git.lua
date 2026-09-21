local spec = require("settings").spec

return {
  spec("lewis6991/gitsigns.nvim", "git.gitsigns"),
  spec("NeogitOrg/neogit", "git.neogit", {
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim",
      "ibhagwan/fzf-lua",
    },
  }),
  spec("sindrets/diffview.nvim", "git.diffview", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  spec("akinsho/git-conflict.nvim", "git.git-conflict"),
}
