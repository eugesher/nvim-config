-- ~/.config/nvim/lua/config/keymaps.lua
-- User-defined keymaps. Plugin-specific mappings live in their plugin specs.

local keymap = vim.keymap.set

-- Quick window navigation: Ctrl + hjkl instead of Ctrl-w hjkl
keymap("n", "<C-h>", "<C-w>h", { desc = "Move to the left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Move to the lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Move to the upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Move to the right window" })

-- Move selected lines up/down in Visual mode (Alt + j/k)
keymap("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
keymap("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Clear search highlight
keymap("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search highlight" })

-- Save the current file
keymap("n", "<leader>w", ":w<CR>", { desc = "Save file" })

-- Close the current buffer.
-- If the Neo-tree file explorer is open in this tab, hand focus to it after
-- deleting the buffer so the editor area isn't left as a [No Name] window.
-- Inside Neo-tree itself, this is a no-op (use `q` or `<leader>e` instead).
keymap("n", "<leader>q", function()
  if vim.bo.filetype == "neo-tree" then
    return
  end
  local tree_win
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      tree_win = win
      break
    end
  end
  vim.cmd("bdelete")
  if tree_win and vim.api.nvim_win_is_valid(tree_win) then
    vim.api.nvim_set_current_win(tree_win)
  end
end, { desc = "Close buffer (focus file tree if open)" })

-- Paste over selection without overwriting the unnamed register
keymap("v", "p", '"_dP', { desc = "Paste without yanking replaced text" })

-- Center the screen after half-page scrolling
keymap("n", "<C-d>", "<C-d>zz", { desc = "Half page down + center" })
keymap("n", "<C-u>", "<C-u>zz", { desc = "Half page up + center" })

-- Disable arrow keys to enforce hjkl navigation
local arrow_keys = { "<Up>", "<Down>", "<Left>", "<Right>" }
for _, key in ipairs(arrow_keys) do
  keymap({ "n", "v" }, key, "<Nop>", { desc = "Arrow keys disabled" })
end
