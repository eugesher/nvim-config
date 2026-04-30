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
        -- Pure-black look applied per highlight group instead of via
        -- `color_overrides`. The previous palette-level approach (overriding
        -- `surface0`/`base`/`mantle`/`crust` to `#000000`) painted multiple
        -- derived groups at once — including `CursorLine`, which then matched
        -- `Normal` and rendered the cursor line invisible. Editing the
        -- highlight groups directly keeps each visual concern independent.
        custom_highlights = function()
          local bg = "#000000"
          local cursor_bg = "#11111b" -- canonical Mocha `crust` — slightly off-black, kept visible against `bg`

          return {
            -- Editor surfaces.
            Normal = { bg = bg },
            NormalNC = { bg = bg },
            SignColumn = { bg = bg },
            LineNr = { bg = bg },
            CursorLineNr = { bg = bg },
            CursorLine = { bg = cursor_bg },
            StatusLine = { bg = bg },
            StatusLineNC = { bg = bg },

            -- Neo-tree surfaces. Neo-tree's built-in `winhighlight` already
            -- remaps `Normal`/`NormalNC`/`EndOfBuffer` (etc.) to its own
            -- `NeoTree*` groups on the tree window, so defining these groups
            -- here is enough to recolour the panel — no extra wiring needed.
            -- `CursorLine` is the exception: neo-tree does NOT include it in
            -- its winhighlight, so the `neo_tree_buffer_enter` handler below
            -- appends the `CursorLine:NeoTreeCursorLine` remap manually.
            NeoTreeNormal = { bg = bg },
            NeoTreeNormalNC = { bg = bg },
            NeoTreeEndOfBuffer = { bg = bg },
            NeoTreeCursorLine = { bg = cursor_bg },
            NeoTreeWinSeparator = { bg = bg },
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
            -- Full-width cursor line in the tree. neo-tree's built-in
            -- `winhighlight` does not include `CursorLine`, so we append a
            -- `CursorLine:NeoTreeCursorLine` remap here. That keeps the tree's
            -- cursor-line styling separable from the editor's, even though
            -- both currently share the same `#11111b` background (defined in
            -- `custom_highlights` above). Appending — rather than assigning —
            -- preserves neo-tree's own `Normal`/`NormalNC`/`EndOfBuffer`
            -- remaps; firing on every buffer-enter keeps the highlight valid
            -- across panel resize and focus changes.
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
