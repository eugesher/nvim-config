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
