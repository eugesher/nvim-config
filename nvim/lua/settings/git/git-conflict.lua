-- defaults verified against git-conflict.nvim v2.1.0-4-ga1badcd (2026-09-12)
--
-- Resolve merge conflicts right in the buffer: highlighted markers, jumps and
-- choosing a side, without opening diffview. A file counts as conflicted when
-- `git diff --diff-filter=U` lists it. Keys match diffview's merge tool
-- (settings/git/diffview.lua): ]x / [x and the <leader>gx group; they exist only
-- while the buffer still has conflict markers.

local M = {}

M.event = { "BufReadPre", "BufNewFile" }

M.keys = {
  { "<leader>gxq", "<cmd>GitConflictListQf<cr>", desc = "Conflicts to quickfix" },
}

-- { modes, lhs, <Plug> mapping of the plugin, desc }
local KEYMAPS = {
  { { "n", "v" }, "<leader>gxo", "<Plug>(git-conflict-ours)", "Conflict: choose OURS" },
  { { "n", "v" }, "<leader>gxt", "<Plug>(git-conflict-theirs)", "Conflict: choose THEIRS" },
  { { "n", "v" }, "<leader>gxb", "<Plug>(git-conflict-base)", "Conflict: choose BASE" },
  { { "n", "v" }, "<leader>gxa", "<Plug>(git-conflict-both)", "Conflict: choose both" },
  { { "n", "v" }, "<leader>gx0", "<Plug>(git-conflict-none)", "Conflict: choose none" },
  { "n", "]x", "<Plug>(git-conflict-next-conflict)", "Next conflict" },
  { "n", "[x", "<Plug>(git-conflict-prev-conflict)", "Previous conflict" },
}

-- The plugin fires both events without data, for the current buffer.
function M.init()
  local group = vim.api.nvim_create_augroup("settings_git_conflict", { clear = true })

  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "GitConflictDetected",
    desc = "Conflict keymaps; no diagnostics while conflict markers are in the buffer",
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      -- LSP floods conflict markers with errors. Left alone if something else
      -- (diffview's merge tool) has already switched them off.
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
  -- Our own buffer-local keys (see KEYMAPS / `init`) instead of co / ct / cb / c0.
  default_mappings = false,
  default_commands = true,
  -- Off on purpose, diagnostics are handled in `init`: the plugin's own switch
  -- calls vim.diagnostic.disable(), which no longer exists in Neovim 0.12.
  disable_diagnostics = false,
  list_opener = "copen",
  -- Must have a background color, otherwise the plugin falls back to its own.
  highlights = {
    incoming = "DiffAdd",
    current = "DiffText",
  },
}

return M
