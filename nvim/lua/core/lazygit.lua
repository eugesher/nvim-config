local trust = require("core.trust")
local user = require("user.settings")

local M = {}

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

function M.edit_hex(hex, line)
  if type(hex) ~= "string" or #hex % 2 ~= 0 or hex:find("%X") then
    return ""
  end
  local names = hex:gsub("%x%x", function(byte)
    return string.char(tonumber(byte, 16))
  end)
  local path = names:match("^[^%z]+")
  if not path or path:match("^%a[%w+.-]*:") then
    return ""
  end
  return M.edit(vim.fn.fnamemodify(path, ":p"), line)
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
  for _, file in ipairs({ own, vim.fs.joinpath(vim.fn.stdpath("config"), "lazygit.yml") }) do
    if vim.uv.fs_stat(file) then
      files[#files + 1] = file
    end
  end
  return files
end

local function git_output(args)
  local ok, job = pcall(vim.system, vim.list_extend({ "git" }, args), { text = true })
  if not ok then
    return nil, nil
  end
  local result = job:wait(2000)
  return result.code == 0 and result.stdout or nil, result.code
end

local RISKY_SECTIONS = {
  credential = true,
  diff = true,
  difftool = true,
  filter = true,
  gpg = true,
  include = true,
  includeif = true,
  interactive = true,
  merge = true,
  mergetool = true,
  pager = true,
  protocol = true,
  sequence = true,
  trailer = true,
  uploadpack = true,
}

local RISKY_CORE = {
  alternaterefscommand = true,
  askpass = true,
  attributesfile = true,
  editor = true,
  fsmonitor = true,
  gitproxy = true,
  hookspath = true,
  pager = true,
  sshcommand = true,
}

local RISKY_REMOTE = { receivepack = true, uploadpack = true, vcs = true }

local function runs_commands(key)
  local section, rest = key:match("^([^.]+)%.(.+)$")
  if not section then
    return false
  end
  if section == "core" then
    return RISKY_CORE[rest] == true
  end
  if section == "remote" then
    return RISKY_REMOTE[rest:match("([^.]+)$")] == true
  end
  if section == "submodule" then
    return rest:match("([^.]+)$") == "update"
  end
  return RISKY_SECTIONS[section] == true
end

local function repo_files()
  local common, code = git_output({ "rev-parse", "--path-format=absolute", "--git-common-dir" })
  if code == 128 then
    return {}
  end
  if not common then
    return nil
  end
  common = common:gsub("\n$", "")
  local worktrees = git_output({ "worktree", "list", "--porcelain", "-z" })
  local main = worktrees and worktrees:match("^worktree ([^%z]+)%z")
  local top = git_output({ "rev-parse", "--show-toplevel" })
  top = top and top:gsub("\n$", "") or common
  local listing = git_output({
    "-C",
    top,
    "config",
    "--includes",
    "--show-scope",
    "--show-origin",
    "-z",
    "--list",
  })
  local hooks = git_output({ "rev-parse", "--path-format=absolute", "--git-path", "hooks" })
  if
    common:find("\n", 1, true)
    or not common:find("^/")
    or not main
    or not listing
    or not hooks
  then
    return nil
  end
  local files = { vim.fs.joinpath(common, "lazygit.yml") }
  for dir in vim.fs.parents(main) do
    files[#files + 1] = vim.fs.joinpath(dir, ".lazygit.yml")
  end
  local origins, risky = {}, false
  local fields = vim.split(listing, "\0", { plain = true })
  for i = 1, #fields - 2, 3 do
    local scope, origin, entry = fields[i], fields[i + 1], fields[i + 2]
    if scope == "local" or scope == "worktree" then
      local path = origin:match("^file:(.+)$")
      if not path then
        return nil
      end
      path = path:find("^/") and path or vim.fs.joinpath(top, path)
      if not vim.uv.fs_lstat(path) then
        return nil
      end
      origins[vim.fs.normalize(path)] = true
      risky = risky or runs_commands(entry:match("^[^\n]*"))
    end
  end
  if risky then
    vim.list_extend(files, vim.tbl_keys(origins))
  end
  hooks = hooks:gsub("\n$", "")
  if vim.uv.fs_stat(hooks) then
    for name in vim.fs.dir(hooks) do
      local path = vim.fs.joinpath(hooks, name)
      if not name:match("%.sample$") and vim.fn.executable(path) == 1 then
        files[#files + 1] = path
      end
    end
  end
  return vim.tbl_filter(function(file)
    return vim.uv.fs_lstat(file) ~= nil
  end, files), main
end

local function geometry()
  local scale = user.git.lazygit_scale
  local height = math.ceil(vim.o.lines * scale) - 1
  local width = math.ceil(vim.o.columns * scale)
  return {
    relative = "editor",
    row = (vim.o.lines - height) / 2,
    col = (vim.o.columns - width) / 2,
    width = width,
    height = height,
  }
end

function M.open(args)
  if vim.fn.executable("lazygit") == 0 then
    vim.notify("lazygit is not installed", vim.log.levels.WARN)
    return
  end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "lazygit" then
      vim.api.nvim_set_current_win(win)
      vim.cmd.startinsert()
      return
    end
  end
  local files, main = repo_files()
  if not files then
    vim.notify("Lazygit not started: git could not describe the repository", vim.log.levels.WARN)
    return
  end
  for _, file in ipairs(files) do
    local real = vim.uv.fs_realpath(file)
    local stat = real and vim.uv.fs_stat(real)
    if not stat or stat.type ~= "file" or stat.size > 64 * 1024 * 1024 then
      vim.notify(
        ("Lazygit not started: %s is not a regular file of at most 64 MB"):format(file),
        vim.log.levels.WARN
      )
      return
    end
  end
  if
    #files > 0
    and not trust.approve(
      "lazygit:" .. main,
      files,
      "Repository " .. main,
      ("has %d git config, hook or lazygit file(s) that make lazygit's git run commands."):format(
        #files
      )
    )
  then
    vim.notify(
      "Lazygit not started: the repository's git settings are not allowed (:ProjectTrust)",
      vim.log.levels.WARN
    )
    return
  end
  local previous = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(
    buf,
    true,
    vim.tbl_extend("force", geometry(), {
      style = "minimal",
      border = user.git.lazygit_scale < 1 and user.ui.border or "none",
    })
  )
  vim.bo[buf].filetype = "lazygit"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_set_hl(0, "LazyGitBorder", { link = "Normal", default = true })
  vim.api.nvim_set_hl(0, "LazyGitFloat", { link = "Normal", default = true })
  vim.wo[win].winhighlight = "FloatBorder:LazyGitBorder,NormalFloat:LazyGitFloat"
  vim.wo[win].winblend = 0
  local group = vim.api.nvim_create_augroup("myconfig.lazygit." .. buf, { clear = true })
  vim.api.nvim_create_autocmd("VimResized", {
    group = group,
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_set_config(win, geometry())
      end
    end,
  })
  local cmd = vim.list_extend({ "lazygit" }, args or {})
  local files = config_files()
  if #files > 0 then
    vim.list_extend(cmd, { "-ucf", table.concat(files, ",") })
  end
  vim.fn.jobstart(cmd, {
    term = true,
    on_exit = function(_, code)
      if code ~= 0 then
        return
      end
      vim.api.nvim_del_augroup_by_id(group)
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_win_is_valid(previous) then
        vim.api.nvim_set_current_win(previous)
      end
      vim.cmd("silent! checktime")
      open_pending()
    end,
  })
  vim.cmd.startinsert()
end

return M
