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
      -- Buffer-local hunk navigation and per-hunk actions. Registered via
      -- `on_attach` so the keymaps only exist in buffers gitsigns has actually
      -- attached to (tracked files in a git repo). `]g` / `[g` mirror
      -- neo-tree's buffer-local cycle (which jumps between changed *files*) —
      -- here they jump between changed *lines* within a single file. The
      -- `<leader>g*` actions live alongside `<leader>gg` (lazygit, registered
      -- globally in `lazygit.lua`); the shared prefix produces a `timeoutlen`
      -- wait identical to the `<leader>d` / `<leader>db*` overlap.
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(modes, lhs, rhs, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(modes, lhs, rhs, opts)
        end

        map({ "n", "x" }, "]g", function()
          gs.nav_hunk("next")
        end, { desc = "Next git hunk" })
        map({ "n", "x" }, "[g", function()
          gs.nav_hunk("prev")
        end, { desc = "Previous git hunk" })

        map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview git hunk" })
        map("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, { desc = "Blame current line" })

        -- Normal-mode stage/reset acts on the hunk under the cursor; Visual
        -- mode passes the selected line range so partial hunks can be staged
        -- or reverted.
        map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage git hunk" })
        map("x", "<leader>gs", function()
          gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Stage selected lines" })
        map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset git hunk" })
        map("x", "<leader>gr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, { desc = "Reset selected lines" })

        map("n", "<leader>gS", gs.stage_buffer, { desc = "Stage entire buffer" })
        map("n", "<leader>gR", gs.reset_buffer, { desc = "Reset entire buffer" })

        -- Hunk text object. gitsigns ships a single `select_hunk` action;
        -- `ih` and `ah` are bound to the same thing because a hunk has no
        -- inside/outside boundary to differentiate.
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", {
          silent = true,
          desc = "Hunk text object",
        })
        map({ "o", "x" }, "ah", ":<C-U>Gitsigns select_hunk<CR>", {
          silent = true,
          desc = "Hunk text object",
        })
      end,
    })
  end,
}
