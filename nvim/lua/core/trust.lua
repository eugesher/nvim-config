local user = require("user.settings")

local M = {}

local root_markers = { "tsconfig.json", "package.json", "jsconfig.json" }

local tool_configs = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  ".eslintrc.json",
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
  ".prettierrc",
  ".prettierrc.json",
  ".prettierrc.json5",
  ".prettierrc.yaml",
  ".prettierrc.yml",
  ".prettierrc.toml",
  ".prettierrc.js",
  ".prettierrc.cjs",
  ".prettierrc.mjs",
  ".prettierrc.ts",
  ".prettierrc.cts",
  ".prettierrc.mts",
  "prettier.config.js",
  "prettier.config.cjs",
  "prettier.config.mjs",
  "prettier.config.ts",
  "prettier.config.cts",
  "prettier.config.mts",
  "package.yaml",
}

local nested_markers = vim.list_extend(vim.deepcopy(root_markers), tool_configs)

M.prettier_configs = vim.tbl_filter(function(name)
  return name:find("prettier", 1, true) ~= nil
end, tool_configs)

M.eslint_configs = vim.tbl_filter(function(name)
  return name:find("eslint", 1, true) ~= nil
end, tool_configs)

local fingerprint_files = {
  "package.json",
  "tsconfig.json",
  "jsconfig.json",
  "package-lock.json",
  "npm-shrinkwrap.json",
  "yarn.lock",
  "pnpm-lock.yaml",
  "bun.lock",
  "bun.lockb",
}

vim.list_extend(fingerprint_files, tool_configs)

table.insert(fingerprint_files, ".vscode/launch.json")

vim.list_extend(fingerprint_files, {
  "node_modules/typescript/lib/tsserver.js",
  "node_modules/typescript/lib/_tsserver.js",
  "node_modules/typescript/lib/typescript.js",
  "node_modules/.bin/vscode-eslint-language-server",
  "node_modules/eslint/package.json",
  "node_modules/prettier/package.json",
  "node_modules/.bin/prettier",
  "node_modules/.bin/prettierd",
})

local tracked_pathspecs = {
  ":(glob)**/package.json",
  ":(glob)**/tsconfig*.json",
  ":(glob)**/jsconfig*.json",
  ":(glob)**/.eslintrc*",
  ":(glob)**/eslint.config.*",
  ":(glob)**/.prettierrc*",
  ":(glob)**/prettier.config.*",
  ":(glob)**/package.yaml",
  ":(glob)**/.env",
  ":(glob)**/node_modules/**",
}

local max_size = 64 * 1024 * 1024

local store_path = vim.fs.joinpath(vim.fn.stdpath("state"), "myconfig", "trust.json")

local hashes = {}
local listings = {}
local git_dirs = {}
local tracked_roots = {}
local timeout_notified = {}

local nvim_trust = vim.fs.joinpath(vim.fn.stdpath("state"), "trust")
local nvim_trust_stat = vim.uv.fs_stat(nvim_trust)
if nvim_trust_stat and bit.band(nvim_trust_stat.mode, tonumber("077", 8)) ~= 0 then
  vim.uv.fs_chmod(nvim_trust, tonumber("600", 8))
end

local function output(cmd)
  local ok, job = pcall(vim.system, cmd, { text = true })
  if not ok then
    return nil, nil
  end
  local result = job:wait(user.trust.git_timeout_ms)
  return result.code == 0 and result.stdout or nil, result.code
end

local READ_FLAGS = bit.bor(vim.uv.constants.O_RDONLY, vim.uv.constants.O_NONBLOCK)

local function read_file(path, limit, expect)
  local fd = vim.uv.fs_open(path, READ_FLAGS, 0)
  if not fd then
    return nil
  end
  local stat = vim.uv.fs_fstat(fd)
  local data
  if
    stat
    and stat.type == "file"
    and stat.size <= limit
    and (not expect or stat.ino == expect.ino and stat.dev == expect.dev)
  then
    local chunks, offset = {}, 0
    while offset < stat.size do
      local chunk = vim.uv.fs_read(fd, stat.size - offset, offset)
      if not chunk or chunk == "" then
        break
      end
      chunks[#chunks + 1] = chunk
      offset = offset + #chunk
    end
    data = offset == stat.size and table.concat(chunks) or nil
  end
  vim.uv.fs_close(fd)
  return data
end

M.read_file = read_file

local function content_hash(path, root)
  if not vim.uv.fs_lstat(path) then
    return "-"
  end
  local real = vim.uv.fs_realpath(path)
  local stat = real and vim.uv.fs_stat(real)
  local outside = root and real and not vim.fs.relpath(root, real)
  if not stat or stat.type ~= "file" or stat.size > max_size or outside then
    return ("%s:%s"):format(stat and stat.type or "broken", real or "")
  end
  local key = table.concat({
    stat.ino,
    stat.size,
    stat.mtime.sec,
    stat.mtime.nsec,
    stat.ctime.sec,
    stat.ctime.nsec,
  }, ":")
  local cached = hashes[real]
  if not cached or cached.key ~= key then
    local data = read_file(real, max_size, stat)
    if not data then
      return "?"
    end
    cached = { key = key, hash = vim.fn.sha256(data) }
    hashes[real] = cached
  end
  return real .. "@" .. cached.hash
end

local function git_marker(root)
  local top = vim.fs.root(root, ".git")
  if not top then
    return false
  end
  local path = vim.fs.joinpath(top, ".git")
  local parts = { top, vim.uv.fs_realpath(path) or "-" }
  local stat = vim.uv.fs_stat(path)
  if stat and stat.type == "file" then
    local gitdir = (read_file(path, 4096, stat) or ""):match("^gitdir: ([^\n]+)")
    local target = gitdir and (gitdir:find("^/") and gitdir or vim.fs.joinpath(top, gitdir))
    vim.list_extend(parts, {
      stat.ino,
      stat.size,
      stat.mtime.sec,
      stat.mtime.nsec,
      target and vim.uv.fs_realpath(target) or "-",
    })
  end
  return table.concat(parts, ":")
end

local function tracked(root)
  local marker = git_marker(root)
  local cached = git_dirs[root]
  if not cached or cached.marker ~= marker then
    local dir, code = output({ "git", "-C", root, "rev-parse", "--absolute-git-dir" })
    if code == 124 or marker and not dir then
      return nil
    end
    cached = { marker = marker, dir = dir and dir:gsub("\n$", "") or false }
    git_dirs[root] = cached
  end
  local dir = cached.dir
  if not dir then
    return ""
  end
  local index = vim.uv.fs_stat(dir .. "/index")
  if index and index.type ~= "file" then
    return "?"
  end
  local key = index
      and table.concat({ index.ino, index.size, index.mtime.sec, index.mtime.nsec }, ":")
    or "-"
  local cached = listings[root]
  if not cached or cached.key ~= key then
    local cmd = { "git", "-C", root, "ls-files", "--stage", "-z", "--" }
    local listing, code = output(vim.list_extend(cmd, tracked_pathspecs))
    if code ~= 0 then
      return nil
    end
    cached = { key = key, hash = listing and vim.fn.sha256(listing) or "?" }
    listings[root] = cached
  end
  return cached.hash
end

local function fingerprint(root)
  local index = tracked(root)
  if not index then
    return nil
  end
  local parts = { "tracked=" .. index }
  for _, name in ipairs(fingerprint_files) do
    parts[#parts + 1] = name .. "=" .. content_hash(vim.fs.joinpath(root, name), root)
  end
  return vim.fn.sha256(table.concat(parts, "\n"))
end

local function read_store()
  local file = io.open(store_path, "r")
  if not file then
    return {}
  end
  local ok, store = pcall(vim.json.decode, file:read("*a") or "")
  file:close()
  return ok and type(store) == "table" and store or {}
end

local function write_store(store)
  vim.fn.mkdir(vim.fs.dirname(store_path), "p", tonumber("700", 8))
  local temp = ("%s.%d.tmp"):format(store_path, vim.uv.os_getpid())
  local fd = vim.uv.fs_open(temp, "w", tonumber("600", 8))
  if not fd then
    return
  end
  local json = vim.json.encode(store)
  local written = vim.uv.fs_write(fd, json)
  local closed = vim.uv.fs_close(fd)
  if written ~= #json or not closed or not vim.uv.fs_rename(temp, store_path) then
    vim.uv.fs_unlink(temp)
  end
end

local ignored = {}

local function ask(subject, changed, what)
  local reason = changed and "changed since it was allowed" or "not decided yet"
  local ok, choice = pcall(
    vim.fn.confirm,
    ("%s (%s) %s Run it?"):format(subject, reason, what),
    "&Allow\n&Deny\n&Ignore",
    3
  )
  return ok and ({ "allow", "deny" })[choice] or nil
end

local function decide(key, current, subject, what)
  local store = read_store()
  local entry = type(store[key]) == "table" and store[key] or {}
  if entry.decision == "deny" then
    return false
  end
  if entry.decision == "allow" and entry.fingerprint == current then
    return true
  end
  if ignored[key] == current then
    return false
  end
  local decision = ask(subject, entry.decision == "allow", what)
  if not decision then
    ignored[key] = current
    return false
  end
  store = read_store()
  store[key] = { decision = decision, fingerprint = current }
  write_store(store)
  return decision == "allow"
end

local function untracked(dir)
  local stat = vim.uv.fs_stat(dir)
  local key = stat and table.concat({ stat.mtime.sec, stat.mtime.nsec }, ":") or "-"
  local cached = tracked_roots[dir]
  if cached and cached.key == key then
    return cached.untracked
  end
  local present = vim.tbl_filter(function(name)
    return vim.uv.fs_lstat(vim.fs.joinpath(dir, name)) ~= nil
  end, nested_markers)
  local result = false
  if #present > 0 then
    local cmd = vim.list_extend({ "git", "-C", dir, "ls-files", "-z", "--" }, present)
    local listing, code = output(cmd)
    result = code ~= 0
    if not result then
      local tracked = {}
      for name in vim.gsplit(listing, "\0", { plain = true, trimempty = true }) do
        tracked[name] = true
      end
      for _, name in ipairs(present) do
        result = result or not tracked[name]
      end
    end
  end
  tracked_roots[dir] = { key = key, untracked = result }
  return result
end

local function holds_marker(dir)
  return vim.iter(nested_markers):any(function(name)
    return vim.uv.fs_lstat(vim.fs.joinpath(dir, name)) ~= nil
  end)
end

function M.root(source)
  local git_root = vim.fs.root(source, ".git")
  local top = git_root or vim.fs.root(source, root_markers)
  if not top then
    return nil
  end
  local name = type(source) == "string" and source or vim.api.nvim_buf_get_name(source)
  if
    not name:find("^/") or not git_root and ("/" .. top .. "/"):find("/node_modules/", 1, true)
  then
    return top
  end
  local nested = git_root and untracked or holds_marker
  local dir = vim.fs.normalize(name)
  if type(source) ~= "string" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fs.dirname(dir)
  end
  while dir ~= top and vim.fs.relpath(top, dir) do
    local inside = vim.fs.relpath(top, dir)
    if not ("/" .. inside .. "/"):find("/node_modules/", 1, true) and nested(dir) then
      return dir
    end
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
  return top
end

function M.parents(dir, names)
  local found = {}
  local home = vim.uv.os_homedir()
  for parent in vim.fs.parents(dir) do
    if parent == home or parent == "/" then
      break
    end
    for _, name in ipairs(names) do
      if vim.uv.fs_lstat(vim.fs.joinpath(parent, name)) then
        table.insert(found, 1, parent)
        break
      end
    end
  end
  return found
end

function M.allowed(root)
  if root == nil or #vim.api.nvim_list_uis() == 0 then
    return false
  end
  local dir = vim.uv.fs_realpath(root)
  if not dir then
    return false
  end
  local store = read_store()
  if type(store[dir]) == "table" and store[dir].decision == "deny" then
    return false
  end
  local current = fingerprint(dir)
  if not current then
    if not timeout_notified[dir] then
      timeout_notified[dir] = true
      vim.notify(
        ("Project code stays off in %s: git failed or took longer than trust.git_timeout_ms"):format(
          dir
        ),
        vim.log.levels.WARN
      )
    end
    return false
  end
  return decide(
    dir,
    current,
    "Project " .. dir,
    "ships code that its TypeScript, eslint, prettier, tests, debugger or :CoverageRun would run."
  )
end

function M.trusted(root)
  local dir = root and vim.uv.fs_realpath(root)
  local current = dir and fingerprint(dir)
  local entry = current and read_store()[dir]
  return type(entry) == "table" and entry.decision == "allow" and entry.fingerprint == current
end

function M.allowed_with_parents(dir, names)
  local dirs = M.parents(dir, names)
  dirs[#dirs + 1] = dir
  return vim.iter(dirs):all(M.allowed)
end

function M.approve(key, files, subject, what)
  if #vim.api.nvim_list_uis() == 0 then
    return false
  end
  local parts = {}
  for _, path in ipairs(files) do
    parts[#parts + 1] = path .. "=" .. content_hash(path)
  end
  table.sort(parts)
  return decide(key, vim.fn.sha256(table.concat(parts, "\n")), subject, what)
end

local function prefixed(dir)
  return dir:match("^lazygit:") or dir:match("^kulala:")
end

local function key_of(dir)
  return prefixed(dir) and dir or vim.uv.fs_realpath(dir)
end

local function forget(dir)
  local store = read_store()
  local key = key_of(dir) or dir
  if store[key] == nil then
    return false
  end
  store[key] = nil
  ignored[key] = nil
  write_store(store)
  return true
end

local function deny(dir)
  local key = key_of(dir)
  if not key then
    return false
  end
  local store = read_store()
  store[key] = { decision = "deny" }
  write_store(store)
  return true
end

local function list()
  local lines = {}
  for dir, entry in vim.spairs(read_store()) do
    if type(entry) == "table" and entry.decision then
      lines[#lines + 1] = ("%-5s %s"):format(entry.decision, dir)
    end
  end
  vim.notify(#lines > 0 and table.concat(lines, "\n") or "No project trust decisions")
end

vim.api.nvim_create_user_command("ProjectTrust", function(args)
  local action = args.fargs[1] or "list"
  local path = table.concat(args.fargs, " ", 2)
  local dir = prefixed(path) and path
    or path ~= "" and vim.fn.fnamemodify(path, ":p")
    or M.root(0)
    or vim.fn.getcwd()
  if action == "list" then
    list()
  elseif action == "forget" then
    vim.notify(forget(dir) and ("Forgot " .. dir) or ("No decision for " .. dir))
  elseif action == "deny" then
    vim.notify(deny(dir) and ("Denied " .. dir) or ("No such directory: " .. dir))
  else
    vim.notify("ProjectTrust: list, forget [dir] or deny [dir]", vim.log.levels.WARN)
  end
end, {
  nargs = "*",
  complete = function(arglead, line)
    if #vim.split(line, "%s+") <= 2 then
      return vim.tbl_filter(function(action)
        return vim.startswith(action, arglead)
      end, { "list", "forget", "deny" })
    end
    return vim.fn.getcompletion(arglead, "dir")
  end,
  desc = "Project trust decisions: list, forget [dir], deny [dir]",
})

return M
