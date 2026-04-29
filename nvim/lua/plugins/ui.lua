-- ~/.config/nvim/lua/plugins/ui.lua
-- Visual layer: colorscheme, status line, file explorer.

local settings = require("config.user-settings")

return {
  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- Load before other plugins so they can use the palette
    config = function()
      require("catppuccin").setup({
        flavour = settings.colorscheme.flavour, -- Variants: latte, frappe, macchiato, mocha
        color_overrides = {
          mocha = { surface0 = "#000000", base = "#000000", mantle = "#000000", crust = "#000000" },
        },
        -- custom_highlights = function(colors)
        --   return {
        --     NeoTreeNormal = { fg = colors.text },
        --     NeoTreeNormalNC = { fg = colors.text },
        --     NeoTreeFileName = { fg = colors.text },
        --     NeoTreeFileIcon = { fg = colors.text },
        --     NeoTreeSymbolicLinkTarget = { fg = colors.text },
        --     NeoTreeDirectoryName = { fg = colors.lavender },
        --     NeoTreeDirectoryIcon = { fg = colors.lavender },
        --     NeoTreeRootName = { fg = colors.lavender },
        --   }
        -- end,
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
        -- Keep Neo-tree open when it becomes the last window in the tab —
        -- closing the active file (`:q`, `ZZ`, `<leader>q`) should drop the
        -- cursor back onto the tree, not exit Neovim. Use `:qa` (or close
        -- the tree first) to actually quit.
        close_if_last_window = false,
        -- Rounded borders on rename / new-file popups, matches the rest of the UI.
        popup_border_style = "rounded",
        -- Both default to true in Neo-tree v3; stated explicitly so a future
        -- bump to a version with different defaults won't silently change UX.
        enable_git_status = true,
        enable_diagnostics = true,

        window = {
          position = settings.neo_tree.position,
          width = settings.neo_tree.window_width,
          mappings = {
            ["<leader><space>"] = "toggle_node",
          },
        },

        filesystem = {
          filtered_items = {
            visible = false, -- start hidden — toggle in-tree with `H`
            hide_dotfiles = settings.neo_tree.hide_dotfiles,
            hide_gitignored = settings.neo_tree.hide_gitignored,
          },
          -- Live-update the tree when files change on disk (git pulls, codegen, etc.).
          use_libuv_file_watcher = true,
          -- Replace netrw entirely so `:edit some-dir/` opens Neo-tree, not netrw.
          hijack_netrw_behavior = "open_default",
        },

        event_handlers = {
          {
            -- After Neo-tree opens as a sidebar, drop the throwaway `[No Name]`
            -- buffer Neovim creates at startup. Without this, `nvim .` and
            -- `nvim` → `<leader>e` both leave an empty editor window next to
            -- the tree. Real files (`nvim README.md`) have a non-empty buffer
            -- name and are not touched.
            event = "neo_tree_window_after_open",
            handler = function(args)
              local tree_win = args and args.winid or vim.api.nvim_get_current_win()
              vim.schedule(function()
                for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                  if win ~= tree_win and vim.api.nvim_win_is_valid(win) then
                    local buf = vim.api.nvim_win_get_buf(win)
                    local empty_unnamed = vim.api.nvim_buf_get_name(buf) == ""
                      and vim.bo[buf].buftype == ""
                      and not vim.bo[buf].modified
                      and vim.api.nvim_buf_line_count(buf) == 1
                      and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ""
                    if empty_unnamed then
                      pcall(vim.api.nvim_win_close, win, false)
                    end
                  end
                end
              end)
            end,
          },
        },
      })

      -- Global keymap — preserved verbatim from the previous nvim-tree setup.
      vim.keymap.set("n", "<leader>e", ":Neotree toggle<CR>", { desc = "Toggle the file explorer" })
    end,
  },
}
