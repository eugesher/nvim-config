local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

local function map_keep_clipboard(mode, lhs, desc)
  vim.keymap.set(mode, lhs, function()
    if vim.v.register:find('^[%+%*"]$') then
      return '"_' .. lhs
    end
    return lhs
  end, { desc = desc, expr = true, silent = true })
end

local function write_all()
  local written = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.bo[buf].modified
      and vim.bo[buf].buftype == ""
      and vim.api.nvim_buf_get_name(buf) ~= ""
    then
      local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd("silent write")
      end)
      if not ok then
        vim.notify(err, vim.log.levels.ERROR)
      elseif not vim.bo[buf].modified then
        written = written + 1
      end
    end
  end
  vim.notify(("%d buffer%s written"):format(written, written == 1 and "" or "s"))
end

map("n", "<leader>w", write_all, "Write all buffers")
map("n", "<leader>Q", "<cmd>qa<CR>", "Quit all")
map("n", "<leader>a", "<cmd>restart!<CR>", "Restart Neovim")

map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
map("n", "n", "nzzzv", "Next match (centered)")
map("n", "N", "Nzzzv", "Previous match (centered)")

map("n", "<C-h>", "<C-w>h", "Go to left window")
map("n", "<C-j>", "<C-w>j", "Go to lower window")
map("n", "<C-k>", "<C-w>k", "Go to upper window")
map("n", "<C-l>", "<C-w>l", "Go to right window")
map("n", "<C-Up>", "<cmd>resize +2<CR>", "Increase window height")
map("n", "<C-Down>", "<cmd>resize -2<CR>", "Decrease window height")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", "Decrease window width")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Increase window width")

map("n", "<C-d>", "<C-d>zz", "Half page down (centered)")
map("n", "<C-u>", "<C-u>zz", "Half page up (centered)")

map("x", "<", "<gv", "Indent left, keep selection")
map("x", ">", ">gv", "Indent right, keep selection")
map("x", "p", "P", "Paste without overwriting the register")
map_keep_clipboard({ "n", "x" }, "d", "Delete (keeps clipboard)")
map_keep_clipboard("n", "D", "Delete to end of line (keeps clipboard)")
map_keep_clipboard("x", "D", "Delete lines (keeps clipboard)")
map_keep_clipboard({ "n", "x" }, "c", "Change (keeps clipboard)")
map_keep_clipboard("n", "C", "Change to end of line (keeps clipboard)")
map_keep_clipboard("x", "C", "Change lines, block to end of line (keeps clipboard)")
map_keep_clipboard("n", "s", "Substitute character (keeps clipboard)")
map_keep_clipboard("x", "s", "Change selection (keeps clipboard)")
map_keep_clipboard("n", "S", "Substitute line (keeps clipboard)")
map_keep_clipboard("x", "S", "Change lines (keeps clipboard)")
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
map("n", "J", function()
  local view = vim.fn.winsaveview()
  vim.cmd("normal! " .. vim.v.count1 .. "J")
  vim.fn.winrestview(view)
end, "Join lines (keep cursor)")

map("n", "]e", function()
  vim.diagnostic.jump({ count = vim.v.count1, severity = vim.diagnostic.severity.ERROR })
end, "Next error")
map("n", "[e", function()
  vim.diagnostic.jump({ count = -vim.v.count1, severity = vim.diagnostic.severity.ERROR })
end, "Previous error")
