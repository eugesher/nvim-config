local icons = require("settings.icons")

local M = {}

M.cmd = {
  "DiffviewOpen",
  "DiffviewFileHistory",
  "DiffviewClose",
  "DiffviewToggleFiles",
  "DiffviewFocusFiles",
}

M.keys = {
  { "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "Diff view (all changes)" },
  { "<leader>gD", "<cmd>DiffviewClose<cr>", desc = "Close diff view" },
  { "<leader>gf", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
  { "<leader>gF", "<cmd>DiffviewFileHistory<cr>", desc = "Repository history" },
  { "<leader>gm", "<cmd>DiffviewOpen<cr>", desc = "Merge tool (conflicts)" },
}

function M.opts()
  local actions = require("diffview.actions")

  local function map(mode, lhs, rhs, desc)
    return { mode, lhs, rhs, { desc = desc } }
  end
  local function off(lhs)
    return { "n", lhs, false }
  end
  local function list(...)
    local result = {}
    for _, part in ipairs({ ... }) do
      vim.list_extend(result, part)
    end
    return result
  end

  local entries = {
    map("n", "<tab>", actions.select_next_entry, "Open the diff for the next file"),
    map("n", "<s-tab>", actions.select_prev_entry, "Open the diff for the previous file"),
    map("n", "[F", actions.select_first_entry, "Open the diff for the first file"),
    map("n", "]F", actions.select_last_entry, "Open the diff for the last file"),
    map("n", "gf", actions.goto_file_edit, "Open the file in the previous tabpage"),
    map("n", "<C-w><C-f>", actions.goto_file_split, "Open the file in a new split"),
    map("n", "<C-w>gf", actions.goto_file_tab, "Open the file in a new tabpage"),
    map("n", "<localleader>e", actions.focus_files, "Bring focus to the file panel"),
    map("n", "<localleader>b", actions.toggle_files, "Toggle the file panel"),
    map("n", "g<C-x>", actions.cycle_layout, "Cycle available layouts"),
    off("<leader>e"),
    off("<leader>b"),
  }

  local conflict_nav = {
    map("n", "[x", actions.prev_conflict, "Go to the previous conflict"),
    map("n", "]x", actions.next_conflict, "Go to the next conflict"),
  }

  local conflict_whole_file = {
    map("n", "<leader>gxO", actions.conflict_choose_all("ours"), "File: choose OURS"),
    map("n", "<leader>gxT", actions.conflict_choose_all("theirs"), "File: choose THEIRS"),
    map("n", "<leader>gxB", actions.conflict_choose_all("base"), "File: choose BASE"),
    map("n", "<leader>gxA", actions.conflict_choose_all("all"), "File: choose all versions"),
    map("n", "dX", actions.conflict_choose_all("none"), "File: delete conflict regions"),
    off("<leader>cO"),
    off("<leader>cT"),
    off("<leader>cB"),
    off("<leader>cA"),
  }

  local folds = {
    map("n", "zo", actions.open_fold, "Expand fold"),
    map("n", "zc", actions.close_fold, "Collapse fold"),
    map("n", "h", actions.close_fold, "Collapse fold"),
    map("n", "za", actions.toggle_fold, "Toggle fold"),
    map("n", "zR", actions.open_all_folds, "Expand all folds"),
    map("n", "zM", actions.close_all_folds, "Collapse all folds"),
  }

  local panel_moves = {
    map("n", "j", actions.next_entry, "Bring the cursor to the next file entry"),
    map("n", "<down>", actions.next_entry, "Bring the cursor to the next file entry"),
    map("n", "k", actions.prev_entry, "Bring the cursor to the previous file entry"),
    map("n", "<up>", actions.prev_entry, "Bring the cursor to the previous file entry"),
    map("n", "<cr>", actions.select_entry, "Open the diff for the selected entry"),
    map("n", "o", actions.select_entry, "Open the diff for the selected entry"),
    map("n", "l", actions.select_entry, "Open the diff for the selected entry"),
    map("n", "<2-LeftMouse>", actions.select_entry, "Open the diff for the selected entry"),
    map("n", "<c-b>", actions.scroll_view(-0.25), "Scroll the view up"),
    map("n", "<c-f>", actions.scroll_view(0.25), "Scroll the view down"),
  }

  return {
    diff_binaries = false,
    enhanced_diff_hl = true,
    git_cmd = { "git" },
    hg_cmd = { "hg" },
    use_icons = true,
    show_help_hints = true,
    watch_index = true,
    icons = {
      folder_closed = icons.ui.folder_closed,
      folder_open = icons.ui.folder_open,
    },
    signs = {
      fold_closed = icons.ui.chevron_right,
      fold_open = icons.ui.chevron_down,
      done = icons.ui.check,
    },
    view = {
      default = {
        layout = "diff2_horizontal",
        disable_diagnostics = true,
        winbar_info = false,
      },
      merge_tool = {
        layout = "diff3_mixed",
        disable_diagnostics = true,
        winbar_info = true,
      },
      file_history = {
        layout = "diff2_horizontal",
        disable_diagnostics = true,
        winbar_info = false,
      },
    },
    file_panel = {
      listing_style = "tree",
      tree_options = {
        flatten_dirs = true,
        folder_statuses = "only_folded",
      },
      win_config = { position = "left", width = 35, win_opts = {} },
    },
    file_history_panel = {
      log_options = {
        git = {
          single_file = { diff_merges = "combined" },
          multi_file = { diff_merges = "first-parent" },
        },
        hg = {
          single_file = {},
          multi_file = {},
        },
      },
      win_config = { position = "bottom", height = 16, win_opts = {} },
    },
    commit_log_panel = { win_config = {} },
    default_args = { DiffviewOpen = {}, DiffviewFileHistory = {} },
    hooks = {},
    keymaps = {
      disable_defaults = false,
      view = list(entries, conflict_nav, {
        map("n", "<leader>gxo", actions.conflict_choose("ours"), "Conflict: choose OURS"),
        map("n", "<leader>gxt", actions.conflict_choose("theirs"), "Conflict: choose THEIRS"),
        map("n", "<leader>gxb", actions.conflict_choose("base"), "Conflict: choose BASE"),
        map("n", "<leader>gxa", actions.conflict_choose("all"), "Conflict: choose all versions"),
        map("n", "<leader>gx0", actions.conflict_choose("none"), "Conflict: delete region"),
        map("n", "dx", actions.conflict_choose("none"), "Conflict: delete region"),
        off("<leader>co"),
        off("<leader>ct"),
        off("<leader>cb"),
        off("<leader>ca"),
      }, conflict_whole_file),
      diff1 = {
        map("n", "g?", actions.help({ "view", "diff1" }), "Open the help panel"),
      },
      diff2 = {
        map("n", "g?", actions.help({ "view", "diff2" }), "Open the help panel"),
      },
      diff3 = {
        map({ "n", "x" }, "2do", actions.diffget("ours"), "Obtain the hunk from OURS"),
        map({ "n", "x" }, "3do", actions.diffget("theirs"), "Obtain the hunk from THEIRS"),
        map("n", "g?", actions.help({ "view", "diff3" }), "Open the help panel"),
      },
      diff4 = {
        map({ "n", "x" }, "1do", actions.diffget("base"), "Obtain the hunk from BASE"),
        map({ "n", "x" }, "2do", actions.diffget("ours"), "Obtain the hunk from OURS"),
        map({ "n", "x" }, "3do", actions.diffget("theirs"), "Obtain the hunk from THEIRS"),
        map("n", "g?", actions.help({ "view", "diff4" }), "Open the help panel"),
      },
      file_panel = list(panel_moves, entries, conflict_nav, conflict_whole_file, folds, {
        map("n", "-", actions.toggle_stage_entry, "Stage / unstage the selected entry"),
        map("n", "s", actions.toggle_stage_entry, "Stage / unstage the selected entry"),
        map("n", "S", actions.stage_all, "Stage all entries"),
        map("n", "U", actions.unstage_all, "Unstage all entries"),
        map("n", "X", actions.restore_entry, "Restore entry to the state on the left side"),
        map("n", "L", actions.open_commit_log, "Open the commit log panel"),
        map("n", "i", actions.listing_style, "Toggle between 'list' and 'tree' views"),
        map("n", "f", actions.toggle_flatten_dirs, "Flatten empty subdirectories in tree listing"),
        map("n", "R", actions.refresh_files, "Update stats and entries in the file list"),
        map("n", "g?", actions.help("file_panel"), "Open the help panel"),
      }),
      file_history_panel = list(panel_moves, entries, folds, {
        map("n", "g!", actions.options, "Open the option panel"),
        map("n", "<localleader>d", actions.open_in_diffview, "Open the entry in a diffview"),
        off("<C-A-d>"),
        map("n", "y", actions.copy_hash, "Copy the commit hash of the entry"),
        map("n", "L", actions.open_commit_log, "Show commit details"),
        map("n", "X", actions.restore_entry, "Restore file to the state from the selected entry"),
        map("n", "g?", actions.help("file_history_panel"), "Open the help panel"),
      }),
      option_panel = {
        map("n", "<tab>", actions.select_entry, "Change the current option"),
        map("n", "q", actions.close, "Close the panel"),
        map("n", "g?", actions.help("option_panel"), "Open the help panel"),
      },
      help_panel = {
        map("n", "q", actions.close, "Close help menu"),
        map("n", "<esc>", actions.close, "Close help menu"),
      },
    },
  }
end

return M
