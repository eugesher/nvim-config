-- ~/.config/nvim/lua/config/autocmds.lua
-- Autocommands: event-driven customizations.

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Briefly highlight yanked text so you can see what was copied
autocmd("TextYankPost", {
  group = augroup("HighlightYank", { clear = true }),
  desc = "Highlight yanked text",
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})

-- Trim trailing whitespace on save
autocmd("BufWritePre", {
  group = augroup("TrimTrailingWhitespace", { clear = true }),
  desc = "Trim trailing whitespace before writing the buffer",
  pattern = "*",
  callback = function()
    local save = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(save)
  end,
})

-- Restore cursor to the last position when reopening a file
autocmd("BufReadPost", {
  group = augroup("RestoreCursor", { clear = true }),
  desc = "Restore the last cursor position on file reopen",
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local line_count = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.api.nvim_win_set_cursor(0, mark)
    end
  end,
})
