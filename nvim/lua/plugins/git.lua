-- Git: hunks in the sign column, hunk actions and blame (gitsigns); the git
-- client (neogit) with diffs, history and the merge tool (diffview).
-- lazygit, vim-fugitive and snacks.nvim are not used.

local spec = require("settings").spec

return {
  spec("lewis6991/gitsigns.nvim", "gitsigns"),
  spec("NeogitOrg/neogit", "neogit", {
    dependencies = {
      "nvim-lua/plenary.nvim",
      "sindrets/diffview.nvim", -- integrations.diffview
      "ibhagwan/fzf-lua", -- integrations.fzf_lua
    },
  }),
  spec("sindrets/diffview.nvim", "diffview", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  -- Conflict resolution right in the buffer, same keys as diffview's merge tool.
  spec("akinsho/git-conflict.nvim", "git-conflict"),
}
