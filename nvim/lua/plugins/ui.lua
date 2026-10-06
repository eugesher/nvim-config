local spec = require("settings").spec

return {
  spec("catppuccin/nvim", "ui.theme", { name = "catppuccin" }),
  spec("nvim-lualine/lualine.nvim", "ui.lualine", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  spec("akinsho/bufferline.nvim", "ui.bufferline", {
    dependencies = { "nvim-tree/nvim-web-devicons", "famiu/bufdelete.nvim" },
  }),
  spec("famiu/bufdelete.nvim"),
  spec("nvim-tree/nvim-web-devicons", "ui.devicons"),
  spec("lukas-reineke/indent-blankline.nvim", "ui.indent", { main = "ibl" }),
  spec("luukvbaal/statuscol.nvim", "ui.statuscol"),
}
