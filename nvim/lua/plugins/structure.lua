-- Code structure: the symbol tree of the current file (aerial, WebStorm's
-- Structure view) and interactive breadcrumbs in the winbar (dropbar).
--
-- Rejected: outline.nvim — LSP is its only real
-- provider and it has no nav window; barbecue.nvim + nvim-navic — breadcrumbs
-- that cannot be clicked or picked. dropbar is the only winbar plugin here.

local spec = require("settings").spec

return {
  spec("stevearc/aerial.nvim", "aerial", {
    dependencies = { "nvim-tree/nvim-web-devicons" },
  }),
  spec("Bekaboo/dropbar.nvim", "dropbar", {
    dependencies = { "nvim-tree/nvim-web-devicons", "nvim-telescope/telescope-fzf-native.nvim" },
  }),
  -- Not telescope: the C port of fzf's matching algorithm (`fzf_lib`), which
  -- dropbar's fuzzy filter in its menus requires. Needs `make` and a C compiler.
  spec("nvim-telescope/telescope-fzf-native.nvim", nil, { build = "make" }),
}
