-- ~/.config/nvim/lua/plugins/gitsigns.lua
-- Git change indicators in the sign column.

return {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPost",
  config = function()
    require("gitsigns").setup({
      signs = {
        add = { text = "█" },
        change = { text = "█" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "█" },
      },
    })
  end,
}
