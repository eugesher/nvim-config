local spec = require("settings").spec

return {
  spec("lewis6991/gitsigns.nvim", "git.gitsigns"),
  spec("kdheepak/lazygit.nvim", "git.lazygit", {
    dependencies = { "nvim-lua/plenary.nvim" },
  }),
  spec("sindrets/diffview.nvim", "git.diffview", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  spec("akinsho/git-conflict.nvim", "git.git-conflict"),
}
