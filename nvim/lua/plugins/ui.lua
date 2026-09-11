-- UI foundation: colorscheme, status line, buffer tabs, icons, indent guides.

local spec = require("settings").spec

return {
  spec("catppuccin/nvim", "theme", { name = "catppuccin" }),
  spec("nvim-lualine/lualine.nvim", "lualine", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  spec("akinsho/bufferline.nvim", "bufferline", {
    dependencies = { "nvim-tree/nvim-web-devicons", "famiu/bufdelete.nvim" },
  }),
  -- No settings: loaded on require by `safe_buffer_delete` (settings/bufferline.lua).
  spec("famiu/bufdelete.nvim"),
  spec("nvim-tree/nvim-web-devicons", "devicons"),
  spec("lukas-reineke/indent-blankline.nvim", "indent", { main = "ibl" }),
}
