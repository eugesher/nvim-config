-- defaults verified against inc-rename.nvim @ddff8bd (2026-09-12)
--
-- LSP rename with a live preview: every occurrence in the project is highlighted
-- and updated as the new name is typed. The preview comes from 'inccommand'
-- (`nosplit`, core/options.lua) — without it the command behaves like a plain
-- rename.
--
-- The rename keys of the LSP layer (`grn` and `<leader>cr`) point here too, so
-- there is one rename in the config and three ways to reach it
-- (settings/lsp/keymaps.lua).

local M = {}

M.cmd = { "IncRename" }

-- `expr`: the command line opens pre-filled with the symbol under the cursor,
-- ready to be edited instead of retyped.
local function rename()
  return ":IncRename " .. vim.fn.expand("<cword>")
end

M.keys = {
  { "<leader>rn", rename, expr = true, desc = "Rename symbol" },
}

M.opts = {
  cmd_name = "IncRename",
  hl_group = "Substitute", -- the same highlight `:s` uses for its preview
  preview_empty_name = false, -- an empty name previews nothing
  show_message = true, -- "Renamed n instances in m files" when done
  save_in_cmdline_history = true,
  -- No input buffer: this config has neither dressing nor snacks, and
  -- `vim.ui.input` is not involved — the command line is the input.
  input_buffer_type = nil,
  post_hook = nil,
}

return M
