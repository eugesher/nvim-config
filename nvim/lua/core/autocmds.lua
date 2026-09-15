local user = require("user.settings")

local function augroup(name)
  return vim.api.nvim_create_augroup("core_" .. name, { clear = true })
end
local autocmd = vim.api.nvim_create_autocmd

autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  desc = "Briefly highlight yanked text",
  callback = function()
    vim.hl.on_yank()
  end,
})

autocmd("BufWritePre", {
  group = augroup("trim_whitespace"),
  desc = "Trim trailing whitespace (markdown excluded: two spaces = line break)",
  callback = function(event)
    local bo = vim.bo[event.buf]
    if bo.filetype == "markdown" or bo.binary or not bo.modifiable then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns silent! %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

autocmd("BufReadPre", {
  group = augroup("restore_cursor"),
  desc = "Restore the last cursor position",
  callback = function(event)
    autocmd("FileType", {
      buffer = event.buf,
      once = true,
      callback = function()
        local ft = vim.bo[event.buf].filetype
        if ft:find("commit") or ft == "gitrebase" or ft == "xxd" or vim.wo.diff then
          return
        end
        local mark = vim.api.nvim_buf_get_mark(event.buf, '"')
        if mark[1] >= 1 and mark[1] <= vim.api.nvim_buf_line_count(event.buf) then
          pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
      end,
    })
  end,
})

if #user.editor.readonly_dirs > 0 then
  autocmd("BufReadPost", {
    group = augroup("readonly_dirs"),
    pattern = vim.tbl_map(function(dir)
      return "*/" .. dir .. "/*"
    end, user.editor.readonly_dirs),
    desc = "Open files from dependency directories read-only",
    callback = function(event)
      vim.bo[event.buf].readonly = true
      vim.bo[event.buf].modifiable = false
    end,
  })
end

autocmd("VimResized", {
  group = augroup("equalize_splits"),
  desc = "Equalize splits after the terminal is resized",
  callback = function()
    local tab = vim.api.nvim_get_current_tabpage()
    vim.cmd("tabdo wincmd =")
    vim.api.nvim_set_current_tabpage(tab)
  end,
})

autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo" },
  desc = "Close auxiliary buffers with q",
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", function()
      if not pcall(vim.cmd.close) then
        vim.api.nvim_buf_delete(event.buf, { force = true })
      end
    end, { buffer = event.buf, silent = true, desc = "Close window" })
  end,
})

autocmd("FileType", {
  group = augroup("formatoptions"),
  desc = "Do not continue comments on new lines",
  callback = function()
    vim.opt_local.formatoptions:remove({ "c", "r", "o" })
  end,
})

autocmd("BufWritePre", {
  group = augroup("auto_mkdir"),
  desc = "Create missing parent directories on write",
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})
