local M = {}

local function mc(name, ...)
  local args = { ... }
  return function()
    require("multicursor-nvim")[name](unpack(args))
  end
end

local nx = { "n", "x" }

M.keys = {
  { "<leader>mn", mc("matchAddCursor", 1), mode = nx, desc = "Add cursor at next match" },
  { "<leader>mN", mc("matchAddCursor", -1), mode = nx, desc = "Add cursor at previous match" },
  { "<leader>ms", mc("matchSkipCursor", 1), mode = nx, desc = "Skip next match" },
  { "<leader>mS", mc("matchSkipCursor", -1), mode = nx, desc = "Skip previous match" },
  { "<leader>mj", mc("lineAddCursor", 1), mode = nx, desc = "Add cursor below" },
  { "<leader>mk", mc("lineAddCursor", -1), mode = nx, desc = "Add cursor above" },
  { "<leader>ma", mc("matchAllAddCursors"), mode = nx, desc = "Cursor on every match" },
  { "<leader>mA", mc("visualToCursors"), mode = "x", desc = "Cursor on each selected line" },
  { "<leader>mp", mc("matchCursors"), mode = "x", desc = "Cursors by pattern in selection" },
  { "<leader>mr", mc("restoreCursors"), desc = "Restore last cursors" },
  { "<leader>mq", mc("clearCursors"), desc = "Clear cursors" },
  { "<leader>mx", mc("transposeCursors", 1), mode = "x", desc = "Rotate text between cursors" },
  { "<leader>mX", mc("transposeCursors", -1), mode = "x", desc = "Rotate text backwards" },
  { "<leader>m=", mc("alignCursors"), desc = "Align cursor columns" },
  { "<C-LeftMouse>", mc("handleMouse"), desc = "Add / remove cursor" },
  { "<C-LeftDrag>", mc("handleMouseDrag"), desc = "Drag cursor selection" },
  { "<C-LeftRelease>", mc("handleMouseRelease"), desc = "Finish cursor selection" },
}

function M.config()
  local multicursor = require("multicursor-nvim")
  multicursor.setup()

  multicursor.addKeymapLayer(function(layer)
    layer(nx, "<Tab>", multicursor.nextCursor, { desc = "Next cursor" })
    layer(nx, "<S-Tab>", multicursor.prevCursor, { desc = "Previous cursor" })
    layer(nx, "<C-q>", multicursor.toggleCursor, { desc = "Disable / enable cursors" })
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
