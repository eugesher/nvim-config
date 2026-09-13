local M = {}

M.lazy = false

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
  enabled = true,
  auto_save = true,
  auto_restore = true,
  auto_create = true,
  auto_restore_last_session = false,
  cwd_change_handling = false,
  single_session_mode = false,

  suppressed_dirs = { "~/", "~/Downloads", "/", "/tmp" },
  allowed_dirs = nil,
  bypass_save_filetypes = PANELS,
  close_filetypes_on_save = PANELS,
  close_unsupported_windows = true,
  preserve_buffer_on_restore = nil,

  git_use_branch_name = true,
  git_auto_restore_on_branch_change = false,
  custom_session_tag = nil,
  resolve_symlinks = false,

  auto_delete_empty_sessions = true,
  purge_after_minutes = nil,

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

  args_allow_single_directory = true,
  args_allow_files_auto_save = false,

  log_level = "error",
  root_dir = vim.fn.stdpath("state") .. "/sessions/",
  show_auto_restore_notif = false,
  restore_error_handler = nil,
  continue_restore_on_error = true,
  lsp_stop_on_restore = false,
  save_and_restore_shada = false,
  lazy_support = true,
  legacy_cmds = false,

  session_lens = {
    picker = "fzf",
    load_on_setup = true,
    picker_opts = nil,
    previewer = "summary",
    shorten_paths = true,
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

  pre_save_cmds = {},
  post_save_cmds = {},
  pre_restore_cmds = {},
  post_restore_cmds = {},
  pre_delete_cmds = {},
  post_delete_cmds = {},
  no_restore_cmds = {},
}

return M
