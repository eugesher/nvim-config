local M = {}

M.cmd = { "IncRename" }

local function rename()
  return ":IncRename " .. vim.fn.expand("<cword>")
end

M.keys = {
  { "<leader>rn", rename, expr = true, desc = "Rename symbol (live preview)" },
}

M.opts = {
  cmd_name = "IncRename",
  hl_group = "Substitute",
  preview_empty_name = false,
  show_message = true,
  save_in_cmdline_history = true,
  input_buffer_type = nil,
  post_hook = nil,
}

return M
