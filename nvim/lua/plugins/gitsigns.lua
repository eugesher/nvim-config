-- Git change indicators in the sign column.

return {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPost",
  config = function()
    require("gitsigns").setup({
      signs = {
        add = { text = "█" },
        change = { text = "█" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "█" },
        untracked = { text = "┆" },
      },
      signs_staged = {
        add = { text = "█" },
        change = { text = "█" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "█" },
        untracked = { text = "┆" },
      },
      numhl = true,
      -- Buffer-local hunk navigation. Registered via `on_attach` so the keymaps
      -- only exist in buffers gitsigns has actually attached to (tracked files
      -- in a git repo). This mirrors neo-tree's buffer-local `[g` / `]g` for
      -- jumping between changed *files* — here they jump between changed
      -- *lines* within a single file.
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(lhs, rhs, desc)
          vim.keymap.set({ "n", "x" }, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("]g", function()
          gs.nav_hunk("next")
        end, "Next git hunk")
        map("[g", function()
          gs.nav_hunk("prev")
        end, "Previous git hunk")
      end,
    })
  end,
}
