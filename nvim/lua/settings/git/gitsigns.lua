-- defaults verified against gitsigns.nvim v2.1.0-55-gf2421c5 (2026-09-12)
--
-- Git hunks in the sign column, hunk staging / reset / preview and blame.
-- All keymaps are buffer-local, created in `on_attach` — they exist only in
-- buffers of files tracked by git. Groups `<leader>gh` / `<leader>gt` live in
-- settings/whichkey/whichkey.lua.

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

M.event = { "BufReadPre", "BufNewFile" }

local function signs(kinds)
  local result = {}
  for _, kind in ipairs(kinds) do
    result[kind] = { text = icons.git_signs[kind], show_count = false }
  end
  return result
end

local function on_attach(bufnr)
  local gitsigns = require("gitsigns")

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
  end

  -- Visual selection as a line range: stage / reset only the selected lines.
  local function selection()
    return { vim.fn.line("."), vim.fn.line("v") }
  end

  -- ]c / [c stay with the built-in diff mode; in a diff window ]h / [h use them.
  local function nav(direction, diff_key)
    return function()
      if vim.wo.diff then
        vim.cmd.normal({ vim.v.count1 .. diff_key, bang = true })
      else
        gitsigns.nav_hunk(direction)
      end
    end
  end

  map("n", "]h", nav("next", "]c"), "Next hunk")
  map("n", "[h", nav("prev", "[c"), "Previous hunk")

  -- On a staged hunk, stage_hunk unstages it (replaces the deprecated undo_stage_hunk).
  map("n", "<leader>ghs", gitsigns.stage_hunk, "Stage / unstage hunk")
  map("v", "<leader>ghs", function()
    gitsigns.stage_hunk(selection())
  end, "Stage / unstage lines")
  map("n", "<leader>ghr", gitsigns.reset_hunk, "Reset hunk")
  map("v", "<leader>ghr", function()
    gitsigns.reset_hunk(selection())
  end, "Reset lines")
  map("n", "<leader>ghS", gitsigns.stage_buffer, "Stage buffer")
  map("n", "<leader>ghU", function()
    gitsigns.reset_buffer_index()
  end, "Unstage buffer")
  map("n", "<leader>ghR", gitsigns.reset_buffer, "Reset buffer")
  map("n", "<leader>ghp", gitsigns.preview_hunk, "Preview hunk")
  -- Also shows the deleted lines of the hunk (replaces the deprecated toggle_deleted).
  map("n", "<leader>ghi", gitsigns.preview_hunk_inline, "Preview hunk inline")
  map("n", "<leader>ghb", function()
    gitsigns.blame_line({ full = true })
  end, "Blame line")
  map("n", "<leader>ghd", function()
    gitsigns.diffthis()
  end, "Diff against index")
  map("n", "<leader>ghD", function()
    gitsigns.diffthis("~")
  end, "Diff against last commit")
  map("n", "<leader>ghq", function()
    gitsigns.setqflist("all")
  end, "All hunks to quickfix")

  map("n", "<leader>gtb", gitsigns.toggle_current_line_blame, "Toggle line blame")
  map("n", "<leader>gtw", gitsigns.toggle_word_diff, "Toggle word diff")

  map("n", "<leader>gB", function()
    gitsigns.blame()
  end, "Blame (file)")

  map({ "o", "x" }, "ih", gitsigns.select_hunk, "Hunk")
  map({ "o", "x" }, "ah", gitsigns.select_hunk, "Hunk")
end

M.opts = {
  signs = signs({ "add", "change", "delete", "topdelete", "changedelete", "untracked" }),
  signs_staged = signs({ "add", "change", "delete", "topdelete", "changedelete" }),
  signs_staged_enable = true,
  signcolumn = true,
  -- Line numbers in the hunk's color; diagnostics leave them alone (core/diagnostics.lua).
  numhl = true,
  linehl = false,
  culhl = false,
  word_diff = false,
  watch_gitdir = { enable = true, follow_files = true },
  auto_attach = true,
  attach_to_untracked = false,
  -- Blame of every line loads big files noticeably: off, toggled with <leader>gtb.
  current_line_blame = false,
  current_line_blame_opts = {
    virt_text = true,
    virt_text_pos = "eol",
    delay = 300,
    ignore_whitespace = false,
    virt_text_priority = 100,
    use_focus = true,
  },
  -- Padded so the annotation does not stick to the end of the code.
  current_line_blame_formatter = " <author>, <author_time:%R> - <summary> ",
  current_line_blame_formatter_nc = " <author>",
  sign_priority = 6,
  update_debounce = 100,
  max_file_length = 40000, -- lines; longer files are not attached
  preview_config = {
    border = user.ui.border,
    style = "minimal",
    relative = "cursor",
    row = 0,
    col = 1,
  },
  diffthis = { split = "aboveleft" },
  count_chars = { "1", "2", "3", "4", "5", "6", "7", "8", "9", ["+"] = ">" },
  gh = false,
  worktrees = {},
  debug_mode = false,
  on_attach = on_attach,
  -- Left at their defaults on purpose:
  --   base             — the index;
  --   diff_opts        — derived from 'diffopt' and follows its changes;
  --   status_formatter — formats `b:gitsigns_status` (lualine reads `b:gitsigns_status_dict`);
  --   blame_formatter  — the built-in layout;
  --   trouble          — true with trouble.nvim installed, so
  --                      `:Gitsigns setqflist` opens the problems panel.
}

return M
