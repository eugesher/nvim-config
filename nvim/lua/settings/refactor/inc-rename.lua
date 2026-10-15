local M = {}

M.cmd = { "IncRename" }

local function rename()
  local word = vim.fn.expand("<cword>")
  return ":IncRename " .. (word:match("^[%w_$]+$") and word or "")
end

M.keys = {
  {
    "<leader>rn",
    rename,
    expr = true,
    replace_keycodes = false,
    desc = "Rename symbol (live preview)",
  },
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
