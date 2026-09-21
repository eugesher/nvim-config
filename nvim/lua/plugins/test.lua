local spec = require("settings").spec

return {
  spec("nvim-neotest/neotest", "test.neotest", {
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
    },
  }),
  spec("andythigpen/nvim-coverage", "test.coverage", {
    dependencies = { "nvim-lua/plenary.nvim" },
  }),
  spec("nvim-neotest/nvim-nio"),
  spec("nvim-neotest/neotest-jest"),
  spec("marilari88/neotest-vitest"),
}
