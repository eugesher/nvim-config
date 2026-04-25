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
          -- Carry forward the previous file-tree look:
          --   files / icons / symlinks → text colour
          --   directories / root       → lavender
          -- (Re-mapped from NvimTree* groups to their Neo-tree equivalents.)
          return {
            NeoTreeNormal = { fg = colors.text },
            NeoTreeNormalNC = { fg = colors.text },
            NeoTreeFileName = { fg = colors.text },
            NeoTreeFileIcon = { fg = colors.text },
            NeoTreeSymbolicLinkTarget = { fg = colors.text },
            NeoTreeDirectoryName = { fg = colors.lavender },
            NeoTreeDirectoryIcon = { fg = colors.lavender },
            NeoTreeRootName = { fg = colors.lavender },
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
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- a separate plugin from nvim-tree.lua: just the icon set
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup({
        -- Close Neovim when Neo-tree is the only window left in the tab.
        close_if_last_window = true,
        -- Rounded borders on rename / new-file popups, matches the rest of the UI.
        popup_border_style = "rounded",
        -- Both default to true in Neo-tree v3; stated explicitly so a future
        -- bump to a version with different defaults won't silently change UX.
        enable_git_status = true,
        enable_diagnostics = true,

        window = {
          position = "left",
          -- nvim-tree dynamically resized between 10% and 25% of the screen
          -- with a content-fit. Neo-tree has no equivalent auto-fit, so we
          -- snapshot a sensible static width inside that range at startup.
          width = math.max(30, math.floor(vim.go.columns * 0.20)),
        },

        filesystem = {
          filtered_items = {
            visible = false, -- start hidden — toggle in-tree with `H`
            -- Mirrors the previous nvim-tree settings:
            --   filters.dotfiles    = true → hide_dotfiles    = true
            --   filters.git_ignored = true → hide_gitignored  = true (also Neo-tree default)
            hide_dotfiles = true,
            hide_gitignored = true,
          },
          -- Live-update the tree when files change on disk (git pulls, codegen, etc.).
          use_libuv_file_watcher = true,
          -- Replace netrw entirely so `:edit some-dir/` opens Neo-tree, not netrw.
          hijack_netrw_behavior = "open_default",
        },
      })

      -- Global keymap — preserved verbatim from the previous nvim-tree setup.
      vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle the file explorer" })
    end,
  },
}
