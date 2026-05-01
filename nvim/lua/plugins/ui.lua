-- ~/.config/nvim/lua/plugins/ui.lua
-- Visual layer: colorscheme, status line, file explorer.

local settings = require("config.user-settings")

-- Module-scope so the catppuccin and lualine specs below share one source.
local black = "#000000"

return {
  -- Colorscheme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000, -- Load before other plugins so they can use the palette
    config = function()
      require("catppuccin").setup({
        flavour = settings.colorscheme.flavour, -- Variants: latte, frappe, macchiato, mocha
        -- Per-group overrides (not `color_overrides`) so `CursorLine` can stay
        -- separable from `Normal` — palette-level edits coupled them together.
        custom_highlights = function(colors)
          local window_bg = black
          local window_cursor_bg = colors.crust
          local float_bg = black
          local float_border_fg = colors.blue
          local float_cursor_bg = colors.crust

          return {
            -- Editor surfaces.
            Normal = { bg = window_bg },
            NormalNC = { bg = window_bg },
            SignColumn = { bg = window_bg },
            LineNr = { bg = window_bg },
            CursorLineNr = { bg = window_cursor_bg },
            CursorLine = { bg = window_cursor_bg },
            StatusLine = { bg = window_bg },
            StatusLineNC = { bg = window_bg },

            -- Neo-tree surfaces. Neo-tree's built-in `winhighlight` already
            -- remaps these, so defining the groups is enough. `CursorLine` is
            -- the exception — appended in the event handler below.
            NeoTreeNormal = { bg = window_bg },
            NeoTreeNormalNC = { bg = window_bg },
            NeoTreeEndOfBuffer = { bg = window_bg },
            NeoTreeCursorLine = { bg = window_cursor_bg },
            NeoTreeWinSeparator = { bg = window_bg },

            -- Generic floating-window baseline: LSP hover, `vim.ui.select`,
            -- the `Snacks.lazygit()` terminal float, and any future plugin
            -- that uses the stock groups. nvim-cmp's `bordered()` windows
            -- remap `Normal` and `FloatBorder` to `Pmenu` / `CmpDocBorder`
            -- via `winhighlight`, so the completion menu is unaffected.
            NormalFloat = { bg = float_bg },
            FloatBorder = { bg = float_bg, fg = float_border_fg },

            -- Telescope pickers. Telescope sets `winhighlight` so the
            -- results window's `CursorLine` is remapped to
            -- `TelescopeSelection` — overriding that group here is enough
            -- to colour the selected row, no per-buffer autocmd needed.
            TelescopeNormal = { bg = float_bg },
            TelescopePreviewNormal = { bg = float_bg },
            TelescopePromptNormal = { bg = float_bg },
            TelescopeResultsNormal = { bg = float_bg },
            TelescopeBorder = { bg = float_bg, fg = float_border_fg },
            TelescopePreviewBorder = { bg = float_bg, fg = float_border_fg },
            TelescopePromptBorder = { bg = float_bg, fg = float_border_fg },
            TelescopeResultsBorder = { bg = float_bg, fg = float_border_fg },
            TelescopeSelection = { bg = float_cursor_bg },
            TelescopeSelectionCaret = { bg = float_cursor_bg },
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
      -- Theme required as a table (not the `"catppuccin-mocha"` string) so
      -- per-section colours can be edited. Black out `b`/`c` (mirrored to
      -- `y`/`x`); leave `a` on its catppuccin blue.
      local theme = require("lualine.themes.catppuccin-mocha")
      for _, mode in pairs(theme) do
        if mode.b then
          mode.b.bg = black
        end
        if mode.c then
          mode.c.bg = black
        end
      end

      require("lualine").setup({
        options = {
          theme = theme,
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
            -- Neo-tree's built-in `winhighlight` doesn't include `CursorLine`;
            -- append the remap so the tree gets a visible cursor row.
            -- Appended (not assigned) to preserve neo-tree's own `Normal`/
            -- `NormalNC`/`EndOfBuffer` remaps.
            event = "neo_tree_buffer_enter",
            handler = function()
              vim.wo.cursorline = true
              vim.wo.cursorlineopt = "both"
              local current = vim.wo.winhighlight
              local addition = "CursorLine:NeoTreeCursorLine"
              if not current:find(addition, 1, true) then
                vim.wo.winhighlight = current == "" and addition or current .. "," .. addition
              end
            end,
          },
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
