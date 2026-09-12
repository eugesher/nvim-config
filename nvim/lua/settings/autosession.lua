-- defaults verified against auto-session v2.5.1-196-g02a5588 (2026-09-12)
--
-- One session per project directory (and per git branch): window layout, buffers
-- and folds come back on the next `nvim` in that directory. `sessionoptions`
-- carries `localoptions` (core/options.lua) — without it filetype-local settings
-- and buffer-local keymaps are lost on restore.
--
-- Commands are the modern `:AutoSession <verb>` form; the legacy `:Session*`
-- aliases are switched off rather than left to shadow them.

local M = {}

-- Eager: a session has to be restored before the first buffer is opened.
M.lazy = false

-- Panels that must never end up in a saved session — a restored layout with an
-- empty tree, a dead debugger panel or an empty problems list is worse than no
-- session at all. **Extend this list whenever a new panel joins the config.**
local PANELS = {
  "neo-tree",
  "oil",
  "dbui",
  "dbout",
  "dap-view",
  "dap-view-term",
  "dap-repl",
  "neotest-summary",
  "neotest-output-panel",
  "coverage",
  "trouble",
  "aerial",
  "lazy",
  "mason",
  "checkhealth",
  "help",
  "qf",
}

local function restore_latest()
  local auto_session = require("auto-session")
  local dir = auto_session.get_root_dir()
  local newest, newest_time = nil, 0
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:match("%.vim$") then
      local stat = vim.uv.fs_stat(dir .. name)
      if stat and stat.mtime.sec > newest_time then
        newest, newest_time = dir .. name, stat.mtime.sec
      end
    end
  end
  if not newest then
    vim.notify("auto-session: no saved sessions yet", vim.log.levels.WARN)
    return
  end
  auto_session.restore_session_file(newest)
end

M.keys = {
  { "<leader>ss", "<cmd>AutoSession restore<cr>", desc = "Restore session" },
  { "<leader>sl", restore_latest, desc = "Restore last session" },
  { "<leader>sf", "<cmd>AutoSession search<cr>", desc = "Find session" },
  { "<leader>sd", "<cmd>AutoSession toggle<cr>", desc = "Toggle auto save" },
  { "<leader>sD", "<cmd>AutoSession delete<cr>", desc = "Delete session" },
  { "<leader>sp", "<cmd>AutoSession purgeOrphaned<cr>", desc = "Purge orphaned sessions" },
}

M.opts = {
  -- Saving / restoring.
  enabled = true,
  auto_save = true,
  auto_restore = true,
  auto_create = true,
  -- Starting `nvim` in a directory with no session of its own must not drag in
  -- somebody else's layout.
  auto_restore_last_session = false,
  cwd_change_handling = false, -- `:cd` does not switch sessions
  single_session_mode = false,

  -- Filtering.
  -- Globs: a session in the home directory or in / would collect every file
  -- ever opened there.
  suppressed_dirs = { "~/", "~/Downloads", "/", "/tmp" },
  allowed_dirs = nil, -- every other directory is allowed
  -- Nothing is saved when a panel is the only thing left open…
  bypass_save_filetypes = PANELS,
  -- …and panels are closed before saving, so they cannot come back empty.
  close_filetypes_on_save = PANELS,
  close_unsupported_windows = true, -- windows without a real file behind them
  preserve_buffer_on_restore = nil, -- every buffer of the session is restored

  -- Git / session naming: a branch is a different working state, so it gets its
  -- own session. Switching branches inside a running Neovim does not swap the
  -- session — that would rearrange the windows under the cursor.
  git_use_branch_name = true,
  git_auto_restore_on_branch_change = false,
  custom_session_tag = nil,
  resolve_symlinks = false,

  -- Deleting.
  auto_delete_empty_sessions = true,
  purge_after_minutes = nil, -- sessions are kept until `<leader>sp`

  -- Saving extra data: DAP breakpoints travel with the session.
  save_extra_data = function(_)
    local ok, breakpoints = pcall(require, "dap.breakpoints")
    if not ok then
      return nil
    end
    local by_file = {}
    for buf, buf_breakpoints in pairs(breakpoints.get()) do
      if vim.api.nvim_buf_is_valid(buf) then
        by_file[vim.api.nvim_buf_get_name(buf)] = buf_breakpoints
      end
    end
    if vim.tbl_isempty(by_file) then
      return nil
    end
    return vim.json.encode({ breakpoints = by_file })
  end,
  restore_extra_data = function(_, extra_data)
    local ok, data = pcall(vim.json.decode, extra_data)
    if not ok or type(data) ~= "table" or not data.breakpoints then
      return
    end
    local dap_ok, breakpoints = pcall(require, "dap.breakpoints")
    if not dap_ok then
      return
    end
    for name, buf_breakpoints in pairs(data.breakpoints) do
      local buf = vim.fn.bufnr(name, true)
      if vim.fn.bufloaded(buf) == 0 then
        vim.fn.bufload(buf)
      end
      for _, breakpoint in pairs(buf_breakpoints) do
        breakpoints.set({
          condition = breakpoint.condition,
          log_message = breakpoint.logMessage,
          hit_condition = breakpoint.hitCondition,
        }, buf, breakpoint.line)
      end
    end
  end,

  -- Argument handling: `nvim .` restores the session of that directory,
  -- `nvim file.ts` opens just the file and saves nothing.
  args_allow_single_directory = true,
  args_allow_files_auto_save = false,

  -- Misc.
  log_level = "error",
  -- Sessions are state, not data: they describe one machine's windows and are
  -- worthless on another one.
  root_dir = vim.fn.stdpath("state") .. "/sessions/",
  show_auto_restore_notif = false,
  restore_error_handler = nil, -- the built-in one ignores fold and help errors
  continue_restore_on_error = true,
  lsp_stop_on_restore = false,
  save_and_restore_shada = false, -- ShaDa is global; a session is per project
  lazy_support = true, -- wait for lazy.nvim before restoring
  legacy_cmds = false, -- only `:AutoSession <verb>`, no `:Session*` aliases

  session_lens = {
    picker = "fzf", -- telescope is not part of this config
    load_on_setup = true, -- telescope-only, stated for completeness
    picker_opts = nil, -- fzf-lua's own window options apply (settings/fzf.lua)
    previewer = "summary", -- the files and the layout the session would restore
    shorten_paths = true, -- `~` instead of the home directory
    -- Keys inside the picker, in insert mode — the same layer fzf-lua itself
    -- uses for its actions.
    mappings = {
      delete_session = { "i", "<C-d>" },
      alternate_session = { "i", "<C-s>" },
      copy_session = { "i", "<C-y>" },
    },
    session_control = {
      control_dir = vim.fn.stdpath("state") .. "/auto_session/",
      control_filename = "session_control.json",
    },
  },

  -- Hooks. Empty on purpose: `close_filetypes_on_save` already closes every
  -- panel before the session is written, so there is
  -- nothing left for a pre-save command to do.
  pre_save_cmds = {},
  post_save_cmds = {},
  pre_restore_cmds = {},
  post_restore_cmds = {},
  pre_delete_cmds = {},
  post_delete_cmds = {},
  no_restore_cmds = {},
}

return M
