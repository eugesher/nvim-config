-- defaults verified against multicursor.nvim @704b99f (2026-09-12)
--
-- Multiple cursors without the GUI key layer: everything lives under
-- `<leader>m`. `<C-n>` is deliberately not used — it belongs to the completion
-- menu (task 08), and this config does not imitate Sublime or VS Code.
--
-- Two layers of keys:
--   * the `<leader>m` ones create cursors and are always available;
--   * the layer registered with `addKeymapLayer` exists only while cursors are
--     alive, so `<Esc>`, `<Tab>` and `<C-q>` keep their normal meaning the rest
--     of the time — `<Tab>` in insert mode (snippets, completion) is never part
--     of the layer.
--
-- The plugin documents no setup options: `signs`, `shallowUndo` and `hlsearch`
-- exist only as type annotations in its source, so `setup()` is called bare.
-- The highlight groups it defines are overridden from the catppuccin palette in
-- settings/theme.lua, where every other plugin's groups live.

local M = {}

-- `require` inside the callback: the first key loads the plugin.
local function mc(name, ...)
  local args = { ... }
  return function()
    require("multicursor-nvim")[name](unpack(args))
  end
end

local nx = { "n", "x" }

M.keys = {
  -- Add / skip a cursor on the next or previous match of the word (or of the
  -- visual selection).
  { "<leader>mn", mc("matchAddCursor", 1), mode = nx, desc = "Add cursor at next match" },
  { "<leader>mN", mc("matchAddCursor", -1), mode = nx, desc = "Add cursor at previous match" },
  { "<leader>ms", mc("matchSkipCursor", 1), mode = nx, desc = "Skip next match" },
  { "<leader>mS", mc("matchSkipCursor", -1), mode = nx, desc = "Skip previous match" },
  -- Cursors above and below, in the direction the keys already mean in Vim.
  { "<leader>mj", mc("lineAddCursor", 1), mode = nx, desc = "Add cursor below" },
  { "<leader>mk", mc("lineAddCursor", -1), mode = nx, desc = "Add cursor above" },
  -- Whole-buffer and selection-wide.
  { "<leader>ma", mc("matchAllAddCursors"), mode = nx, desc = "Cursor on every match" },
  { "<leader>mA", mc("visualToCursors"), mode = "x", desc = "Cursor on each selected line" },
  { "<leader>mp", mc("matchCursors"), mode = "x", desc = "Cursors by pattern in selection" },
  -- Managing the set of cursors.
  { "<leader>mr", mc("restoreCursors"), desc = "Restore last cursors" },
  { "<leader>mq", mc("clearCursors"), desc = "Clear cursors" },
  { "<leader>mx", mc("transposeCursors", 1), mode = "x", desc = "Rotate text between cursors" },
  { "<leader>mX", mc("transposeCursors", -1), mode = "x", desc = "Rotate text backwards" },
  { "<leader>m=", mc("alignCursors"), desc = "Align cursor columns" },
  -- Mouse. Drag and release are what make a click-drag add a selection rather
  -- than a bare cursor.
  { "<C-LeftMouse>", mc("handleMouse"), desc = "Add / remove cursor" },
  { "<C-LeftDrag>", mc("handleMouseDrag"), desc = "Drag cursor selection" },
  { "<C-LeftRelease>", mc("handleMouseRelease"), desc = "Finish cursor selection" },
}

function M.config()
  local multicursor = require("multicursor-nvim")
  multicursor.setup()

  -- Only while cursors exist. `<Tab>` is `<C-i>` in a terminal, so the jump
  -- list gives way to cursor rotation for as long as the cursors are there.
  -- `layer` takes the arguments of `vim.keymap.set`, descriptions included.
  multicursor.addKeymapLayer(function(layer)
    layer(nx, "<Tab>", multicursor.nextCursor, { desc = "Next cursor" })
    layer(nx, "<S-Tab>", multicursor.prevCursor, { desc = "Previous cursor" })
    layer(nx, "<C-q>", multicursor.toggleCursor, { desc = "Disable / enable cursors" })
    -- First `<Esc>`: bring disabled cursors back or drop them all. With no
    -- cursors left the layer is gone, so the next `<Esc>` is the global one
    -- again and clears the search highlight (core/keymaps.lua).
    layer("n", "<Esc>", function()
      if not multicursor.cursorsEnabled() then
        multicursor.enableCursors()
      else
        multicursor.clearCursors()
      end
    end, { desc = "Enable or clear cursors" })
  end)
end

return M
