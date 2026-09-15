local M = {}

M.event = { "BufReadPre", "BufNewFile" }

M.keys = {
  { "<leader>gxq", "<cmd>GitConflictListQf<cr>", desc = "Conflicts to quickfix" },
}

local KEYMAPS = {
  { { "n", "v" }, "<leader>gxo", "<Plug>(git-conflict-ours)", "Conflict: choose OURS" },
  { { "n", "v" }, "<leader>gxt", "<Plug>(git-conflict-theirs)", "Conflict: choose THEIRS" },
  { { "n", "v" }, "<leader>gxb", "<Plug>(git-conflict-base)", "Conflict: choose BASE" },
  { { "n", "v" }, "<leader>gxa", "<Plug>(git-conflict-both)", "Conflict: choose both" },
  { { "n", "v" }, "<leader>gx0", "<Plug>(git-conflict-none)", "Conflict: choose none" },
  { "n", "]x", "<Plug>(git-conflict-next-conflict)", "Next conflict" },
  { "n", "[x", "<Plug>(git-conflict-prev-conflict)", "Previous conflict" },
}

function M.init()
  local group = vim.api.nvim_create_augroup("settings_git_conflict", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitConflictDetected",
    desc = "Conflict keymaps; no diagnostics while conflict markers are in the buffer",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if vim.diagnostic.is_enabled({ bufnr = buf }) then
        vim.diagnostic.enable(false, { bufnr = buf })
        vim.b[buf].git_conflict_hid_diagnostics = true
      end
      for _, map in ipairs(KEYMAPS) do
        vim.keymap.set(map[1], map[2], map[3], { buffer = buf, remap = true, desc = map[4] })
      end
    end,
  })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitConflictResolved",
    desc = "Drop conflict keymaps, bring diagnostics back",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      if vim.b[buf].git_conflict_hid_diagnostics then
        vim.b[buf].git_conflict_hid_diagnostics = nil
        vim.diagnostic.enable(true, { bufnr = buf })
      end
      for _, map in ipairs(KEYMAPS) do
        pcall(vim.keymap.del, map[1], map[2], { buffer = buf })
      end
    end,
  })
end

M.opts = {
  default_mappings = false,
  default_commands = true,
  disable_diagnostics = false,
  list_opener = "copen",
  highlights = {
    incoming = "DiffAdd",
    current = "DiffText",
  },
}

return M
