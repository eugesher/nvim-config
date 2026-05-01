-- ~/.config/nvim/lua/plugins/bufferline.lua
-- Tab line: bufferline.nvim renders open buffers as clickable tabs along the
-- top of the window. Replaces nvim's bare `:buffers` listing with an IDE-style
-- tab strip while keeping nvim's underlying buffer model intact (one buffer
-- per loaded file; tabs in nvim remain about *window layouts*, not files).
--
-- Layout:
--   * bufferline owns rendering + click handlers; its own commands
--     (`:BufferLineCycleNext`, `:BufferLinePick`, `:BufferLineCloseOthers`, …)
--     drive every keymap below — we never reach into the rendering internals.
--   * `famiu/bufdelete.nvim` is loaded as a dependency to provide a *safe*
--     buffer close: it switches the window to the next listed buffer, then
--     deletes. nvim's stock `:bdelete` collapses any split that was showing
--     the buffer, which is the wrong behaviour for a "close this tab" click.
--   * `nvim-web-devicons` is already pulled in by lualine and neo-tree — it's
--     listed here too as an explicit dependency for clarity (lazy.nvim
--     de-duplicates plugin loads).
--   * Catppuccin integration is wired through `opts.highlights` — the helper
--     `catppuccin.groups.integrations.bufferline.get()` returns palette-aware
--     highlight overrides. catppuccin loads first (`priority = 1000`), so the
--     module is available when bufferline's `config()` runs on `VeryLazy`.
--   * `offsets` reserves a column above neo-tree so the tab strip sits over
--     the editor area instead of crossing under the file tree.

local settings = require("config.user-settings")

-- Safe buffer close routed through bufdelete.nvim. Used by:
--   * bufferline's `close_command` (the tab's "x" icon) and
--     `right_mouse_command` (right-click on a tab),
--   * the `<leader>bd` keymap below.
-- Splitting this into a named helper keeps the policy (what to do with
-- modified buffers, whether to force) in one place rather than scattered
-- across three call sites.
local function safe_buffer_delete(bufnr, force)
  local bufdelete = require("bufdelete")
  if not force and vim.bo[bufnr].modified then
    -- `2` is the default-button index — defaults to "No" so a stray <CR>
    -- never discards unsaved work.
    local choice = vim.fn.confirm("Buffer modified — discard changes?", "&Yes\n&No", 2)
    if choice ~= 1 then
      return
    end
    force = true
  end
  bufdelete.bufdelete(bufnr, force)
end

return {
  "akinsho/bufferline.nvim",
  version = "*", -- Pin to the latest stable release tag
  event = "VeryLazy",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "famiu/bufdelete.nvim",
    -- Canonical GitHub slug — lazy.nvim resolves dependencies by URL, not by
    -- the `name = "catppuccin"` alias set in `ui.lua`. Using the short alias
    -- here silently fails to load catppuccin in time for our `config()`.
    "catppuccin/nvim",
  },
  config = function()
    require("bufferline").setup({
      options = {
        -- Buffers, not nvim tabpages — IDE-like one-tab-per-file model.
        mode = "buffers",
        -- Render an ordinal index next to each name so `<leader>1..9` jumps
        -- have a visible target. "buffer_id" would show nvim's internal
        -- buffer number, which doesn't line up with the keymap range.
        numbers = "ordinal",
        close_command = function(bufnr)
          safe_buffer_delete(bufnr, false)
        end,
        right_mouse_command = function(bufnr)
          safe_buffer_delete(bufnr, false)
        end,
        diagnostics = settings.bufferline.diagnostics,
        diagnostics_indicator = function(count, _, _, _)
          return "(" .. count .. ")"
        end,
        offsets = {
          {
            filetype = "neo-tree",
            text = "File Explorer",
            text_align = "left",
            separator = true,
            highlight = "Directory",
          },
        },
        show_buffer_close_icons = true,
        -- Right-edge global "close all" icon — off, the per-tab close icons
        -- plus `<leader>bo` cover the same ground without a misclick hazard.
        show_close_icon = false,
        show_modified_icon = true,
        truncate_names = true,
        color_icons = true,
        always_show_bufferline = settings.bufferline.always_show,
        separator_style = settings.bufferline.separator_style,
        indicator = { style = "underline" },
      },
      -- Palette-aware highlights from catppuccin. Wrapped in pcall so a
      -- colorscheme swap (or the integration module being moved/renamed in a
      -- future catppuccin release) degrades gracefully to bufferline's
      -- defaults instead of an error during `config()`.
      highlights = (function()
        local ok, integration = pcall(require, "catppuccin.groups.integrations.bufferline")
        return ok and integration.get() or {}
      end)(),
    })

    -- Buffer keymaps. Live under the `<leader>b` namespace ("**b**uffer")
    -- with the `]b` / `[b` pair following Tim Pope's unimpaired convention
    -- for "next/previous in some sequence".
    local map = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { silent = true, desc = desc })
    end

    map("]b", "<cmd>BufferLineCycleNext<CR>", "Buffer: next")
    map("[b", "<cmd>BufferLineCyclePrev<CR>", "Buffer: previous")
    local function delete_current_buffer()
      safe_buffer_delete(vim.api.nvim_get_current_buf(), false)
    end
    map("<leader>bd", delete_current_buffer, "Buffer: delete (safe)")
    map("<leader>q", delete_current_buffer, "Buffer: delete (safe)")
    map("<leader>bp", "<cmd>BufferLinePick<CR>", "Buffer: pick")
    map("<leader>b>", "<cmd>BufferLineMoveNext<CR>", "Buffer: move right")
    map("<leader>b<", "<cmd>BufferLineMovePrev<CR>", "Buffer: move left")
    map("<leader>bo", "<cmd>BufferLineCloseOthers<CR>", "Buffer: close others")
    map("<leader>bP", "<cmd>BufferLineTogglePin<CR>", "Buffer: toggle pin")

    -- Jump-to-ordinal: `<leader>1` … `<leader>9` map to the nth visible tab.
    -- Generated in a loop because hand-written keys = { ... } entries would
    -- be nine near-identical lines.
    for i = 1, 9 do
      map(
        "<leader>" .. i,
        "<cmd>BufferLineGoToBuffer " .. i .. "<CR>",
        "Buffer: jump to " .. i
      )
    end
  end,
}
