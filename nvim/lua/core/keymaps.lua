-- Global, plugin-independent keymaps. Plugin keymaps live in settings/*,
-- buffer-local ones in after/ftplugin/*.
--
-- Not defined here on purpose:
--   * `<leader>q` (close buffer) — settings/bufferline.lua, with bufdelete.nvim.
--   * `]q` / `[q` — native since Neovim 0.11 (`:cnext` / `:cprevious` with
--     count support); redefining them would only lose the count.
--
-- `<A-j>` / `<A-k>` (move line/selection) are the only Alt mappings in the
-- config — a deliberate exception to the "no Alt layer" rule.

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

-- Files / quitting
map("n", "<leader>w", "<cmd>write<CR>", "Write buffer")
map("n", "<leader>Q", "<cmd>qa<CR>", "Quit all")

-- Search
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
map("n", "n", "nzzzv", "Next match (centered)")
map("n", "N", "Nzzzv", "Previous match (centered)")

-- Windows
map("n", "<C-h>", "<C-w>h", "Go to left window")
map("n", "<C-j>", "<C-w>j", "Go to lower window")
map("n", "<C-k>", "<C-w>k", "Go to upper window")
map("n", "<C-l>", "<C-w>l", "Go to right window")
map("n", "<C-Up>", "<cmd>resize +2<CR>", "Increase window height")
map("n", "<C-Down>", "<cmd>resize -2<CR>", "Decrease window height")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", "Decrease window width")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Increase window width")

-- Scrolling
map("n", "<C-d>", "<C-d>zz", "Half page down (centered)")
map("n", "<C-u>", "<C-u>zz", "Half page up (centered)")

-- Editing. Visual maps use "x", not "v": "v" also covers Select mode, where
-- typed characters must replace the selection (snippet placeholders).
map("x", "<", "<gv", "Indent left, keep selection")
map("x", ">", ">gv", "Indent right, keep selection")
-- Visual `P` puts without yanking the replaced text. Unlike `"_dP` it also
-- works when the selection ends at the end of the line.
map("x", "p", "P", "Paste without overwriting the register")
-- Move line / selection, reindenting it at the new place. Counts work (`3<A-j>`);
-- `silent!` turns a move past the buffer edge into a no-op instead of E16.
map("n", "<A-j>", "<cmd>silent! execute 'move .+' . v:count1<CR>==", "Move line down")
map("n", "<A-k>", "<cmd>silent! execute 'move .-' . (v:count1 + 1)<CR>==", "Move line up")
map(
  "x",
  "<A-j>",
  [[:<C-u>silent! execute "'<,'>move '>+" . v:count1<CR>gv=gv]],
  "Move selection down"
)
map(
  "x",
  "<A-k>",
  [[:<C-u>silent! execute "'<,'>move '<-" . (v:count1 + 1)<CR>gv=gv]],
  "Move selection up"
)
-- Join lines without moving the cursor; keeps the count (`3J`) and mark `z`.
map("n", "J", function()
  local view = vim.fn.winsaveview()
  vim.cmd("normal! " .. vim.v.count1 .. "J")
  vim.fn.winrestview(view)
end, "Join lines (keep cursor)")

-- Diagnostics: errors only. `]d` / `[d` (all severities) are native.
map("n", "]e", function()
  vim.diagnostic.jump({ count = vim.v.count1, severity = vim.diagnostic.severity.ERROR })
end, "Next error")
map("n", "[e", function()
  vim.diagnostic.jump({ count = -vim.v.count1, severity = vim.diagnostic.severity.ERROR })
end, "Previous error")
