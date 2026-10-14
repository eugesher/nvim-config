local user = require("user.settings")

local M = {}

M.cmd = {
  "LazyGit",
  "LazyGitCurrentFile",
  "LazyGitLog",
  "LazyGitFilter",
  "LazyGitFilterCurrentFile",
  "LazyGitConfig",
}

local BORDERS = {
  single = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
  double = { "╔", "═", "╗", "║", "╝", "═", "╚", "║" },
  rounded = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
  bold = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
  solid = { " ", " ", " ", " ", " ", " ", " ", " " },
}

local NO_BORDER = { "", "", "", "", "", "", "", "" }

local pending

function M.edit(path, line)
  pending = { path = path, line = line }
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "lazygit" and vim.bo[buf].channel > 0 then
      vim.api.nvim_chan_send(vim.bo[buf].channel, "q")
    end
  end
  return ""
end

local function open_pending()
  if not pending then
    return
  end
  local target = pending
  pending = nil
  vim.cmd.edit(vim.fn.fnameescape(target.path))
  if target.line then
    pcall(vim.api.nvim_win_set_cursor, 0, { target.line, 0 })
  end
end

local function config_files()
  local files = {}
  local own = vim.fs.joinpath(
    vim.env.XDG_CONFIG_HOME or vim.fs.normalize("~/.config"),
    "lazygit",
    "config.yml"
  )
  if vim.uv.fs_stat(own) then
    files[#files + 1] = own
  end
  files[#files + 1] = vim.fs.joinpath(vim.fn.stdpath("config"), "lazygit.yml")
  return files
end

function M.init()
  local g = vim.g
  g.lazygit_floating_window_winblend = 0
  g.lazygit_floating_window_scaling_factor = user.git.lazygit_scale
  g.lazygit_floating_window_border_chars = user.git.lazygit_scale < 1 and BORDERS[user.ui.border]
    or NO_BORDER
  g.lazygit_floating_window_use_plenary = 0
  g.lazygit_use_neovim_remote = 0
  g.lazygit_use_custom_config_file_path = 1
  g.lazygit_config_file_path = config_files()
  g.lazygit_on_exit_callback = open_pending
end

M.keys = {
  { "<leader>gg", "<cmd>LazyGit<cr>", desc = "Lazygit" },
  { "<leader>gl", "<cmd>LazyGitLog<cr>", desc = "Log (lazygit)" },
}

return M
