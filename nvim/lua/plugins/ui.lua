-- ~/.config/nvim/lua/plugins/ui.lua
-- Visual layer: colorscheme, status line, file explorer.

return {
  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- Load before other plugins so they can use the palette
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- Variants: latte, frappe, macchiato, mocha
        color_overrides = {
          mocha = { surface0 = "#000000", base = "#000000", mantle = "#000000", crust = "#000000" },
        },
        custom_highlights = function(colors)
          return {
            NvimTreeNormal = { fg = colors.text },
            NvimTreeExecFile = { fg = colors.text },
            NvimTreeSpecialFile = { fg = colors.text },
            NvimTreeImageFile = { fg = colors.text },
            NvimTreeSymlink = { fg = colors.text },
            NvimTreeFolderName = { fg = colors.lavender },
            NvimTreeOpenedFolderName = { fg = colors.lavender },
            NvimTreeEmptyFolderName = { fg = colors.lavender },
            NvimTreeFolderIcon = { fg = colors.lavender },
            NvimTreeRootFolder = { fg = colors.lavender },
          }
        end,
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons", "catppuccin" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "catppuccin-mocha",
          component_separators = { left = "│", right = "│" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = {
            min = function()
              return math.floor(vim.go.columns * 0.10)
            end,
            max = function()
              return math.floor(vim.go.columns * 0.25)
            end,
            padding = 2,
          },
        },
        filters = { dotfiles = true },
        git = { enable = true },
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle the file explorer" })
    end,
  },
}
