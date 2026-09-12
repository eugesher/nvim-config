-- Tests: the neotest framework with adapters for Jest and Vitest. Both are
-- registered at once — neotest picks the one that matches the project.
-- vim-test is not used: no test tree, no inline statuses, no watch panel
-- (decision recorded in task 18).

local spec = require("settings").spec

return {
  spec("nvim-neotest/neotest", "neotest", {
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter", -- the adapters parse tests with it
      "nvim-neotest/neotest-jest",
      "marilari88/neotest-vitest",
    },
  }),
  spec("nvim-neotest/nvim-nio"),
  spec("nvim-neotest/neotest-jest"),
  spec("marilari88/neotest-vitest"),
}
