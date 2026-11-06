local ALLOW, DENY = 1, 2

local function hex(text)
  return (text:gsub(".", function(char)
    return ("%02x"):format(char:byte())
  end))
end

local function repo(t, name)
  local root = t.project(name or "repo", { ["src/a.ts"] = "" })
  t.git(root, "init", "-q")
  vim.fn.chdir(root)
  return root
end

local function lazygit(t)
  local started = {}
  local executable = vim.fn.executable
  t.stub(vim.fn, "executable", function(name)
    return name == "lazygit" and 1 or executable(name)
  end)
  t.stub(vim.fn, "jobstart", function(cmd)
    started[#started + 1] = cmd
    return 1
  end)
  return require("core.lazygit"), started
end

local function close_floats()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      vim.api.nvim_win_close(win, true)
    end
  end
end

local function approval_set(t)
  local sets = {}
  local trust = require("core.trust")
  t.stub(trust, "approve", function(key, files)
    sets[#sets + 1] = { key = key, files = files }
    return true
  end)
  return sets
end

local function relative(files, root)
  local out = vim.tbl_map(function(file)
    return vim.fs.relpath(root, file) or file
  end, files)
  table.sort(out)
  return out
end

return {
  {
    "RULE-018 a repository without command-running files starts lazygit unasked",
    function(t)
      repo(t)
      local asked = t.ui(DENY)
      local lg, started = lazygit(t)
      lg.open()
      t.eq({ #started, #asked }, { 1, 0 })
      t.eq(started[1][1], "lazygit")
    end,
  },
  {
    "RULE-018 an executable hook needs approval: Deny keeps lazygit closed",
    function(t)
      local root = repo(t)
      t.write(vim.fs.joinpath(root, ".git/hooks/pre-commit"), "#!/bin/sh\n", "755")
      local asked = t.ui(DENY)
      local lg, started = lazygit(t)
      lg.open()
      t.eq({ #started, #asked }, { 0, 1 })
      t.ok(asked[1]:find("Repository " .. root, 1, true), asked[1])
      t.ok(t.noted("not allowed"), vim.inspect(t.notes()))
      t.eq(t.store()["lazygit:" .. root].decision, "deny")
    end,
  },
  {
    "RULE-018 Allow starts lazygit and holds until a file in the set changes",
    function(t)
      local root = repo(t)
      local hook = t.write(vim.fs.joinpath(root, ".git/hooks/pre-push"), "#!/bin/sh\n", "755")
      local asked = t.ui(ALLOW)
      local lg, started = lazygit(t)
      lg.open()
      close_floats()
      lg.open()
      close_floats()
      t.eq({ #started, #asked }, { 2, 1 })
      t.write(hook, "#!/bin/sh\nexit 0\n", "755")
      lg.open()
      t.eq({ #started, #asked }, { 3, 2 })
    end,
  },
  {
    "RULE-018 outside a repository lazygit starts without a prompt",
    function(t)
      vim.fn.chdir(t.project("plain"))
      local asked = t.ui(DENY)
      local lg, started = lazygit(t)
      lg.open()
      t.eq({ #started, #asked }, { 1, 0 })
    end,
  },
  {
    "RULE-018 a missing lazygit binary is reported, nothing starts",
    function(t)
      repo(t)
      local started = {}
      t.stub(vim.fn, "executable", function()
        return 0
      end)
      t.stub(vim.fn, "jobstart", function(cmd)
        started[#started + 1] = cmd
      end)
      require("core.lazygit").open()
      t.eq(#started, 0)
      t.ok(t.noted("lazygit is not installed"), vim.inspect(t.notes()))
    end,
  },
  {
    "RULE-018 a set member that is not a regular file refuses to start",
    function(t)
      local root = repo(t)
      vim.fn.mkdir(vim.fs.joinpath(root, ".git/lazygit.yml"), "p")
      t.ui(ALLOW)
      local lg, started = lazygit(t)
      lg.open()
      t.eq(#started, 0)
      t.ok(t.noted("is not a regular file"), vim.inspect(t.notes()))
    end,
  },
  {
    "RULE-019 a hex path is decoded and opened as an absolute path",
    function(t)
      local root = repo(t)
      local lg = require("core.lazygit")
      local opened = {}
      lg.edit = function(path, line)
        opened[#opened + 1] = { path, line }
        return ""
      end
      lg.edit_hex(hex("src/a.ts"), 12)
      lg.edit_hex(hex("src/b c.ts") .. "00" .. hex("ignored"), nil)
      t.eq(opened, {
        { vim.fs.joinpath(root, "src/a.ts"), 12 },
        { vim.fs.joinpath(root, "src/b c.ts") },
      })
    end,
  },
  {
    "RULE-019 malformed hex and scheme-like paths are dropped",
    function(t)
      repo(t)
      local lg = require("core.lazygit")
      local opened = 0
      lg.edit = function()
        opened = opened + 1
        return ""
      end
      for _, input in ipairs({
        "abc",
        "zz",
        hex("a") .. "g0",
        hex("file:///etc/passwd"),
        hex("term://bash"),
        hex("C:x"),
        hex("a+b.c-d:x"),
        "00" .. hex("a"),
        "",
        42,
      }) do
        t.eq(lg.edit_hex(input), "", "returns empty for " .. vim.inspect(input))
      end
      t.eq(opened, 0)
    end,
  },
  {
    "RULE-019 a leading dot or slash is a plain path",
    function(t)
      local root = repo(t)
      local lg = require("core.lazygit")
      local opened = {}
      lg.edit = function(path)
        opened[#opened + 1] = path
        return ""
      end
      lg.edit_hex(hex("./src/a.ts"))
      lg.edit_hex(hex("/tmp/x:1"))
      t.eq(opened, { vim.fs.joinpath(root, "src/a.ts"), "/tmp/x:1" })
    end,
  },
  {
    "RULE-040 local config keys that run commands put .git/config in the set",
    function(t)
      local keys = {
        { "core.pager", "less" },
        { "core.editor", "vi" },
        { "core.hooksPath", "h" },
        { "core.sshCommand", "ssh" },
        { "core.fsmonitor", "true" },
        { "diff.x.textconv", "cat" },
        { "filter.lfs.clean", "cat" },
        { "merge.x.driver", "cat" },
        { "credential.helper", "store" },
        { "gpg.program", "gpg" },
        { "remote.origin.uploadpack", "x" },
        { "remote.origin.receivepack", "x" },
        { "submodule.lib.update", "!cat" },
        { "sequence.editor", "vi" },
        { "uploadpack.packObjectsHook", "x" },
      }
      local missed = {}
      for i, pair in ipairs(keys) do
        local root = repo(t, "r" .. i)
        t.git(root, "config", "--local", pair[1], pair[2])
        local sets = approval_set(t)
        local lg = lazygit(t)
        lg.open()
        close_floats()
        local files = sets[1] and relative(sets[1].files, root) or {}
        if not vim.list_contains(files, ".git/config") then
          missed[#missed + 1] = pair[1]
        end
        package.loaded["core.lazygit"] = nil
      end
      t.eq(missed, {})
    end,
  },
  {
    "RULE-040 Q10 pinned: harmless keys and alias.* leave .git/config out",
    function(t)
      local keys = {
        { "user.name", "x" },
        { "core.autocrlf", "input" },
        { "alias.co", "!rm -rf /" },
        { "url.https://x/.insteadOf", "gh:" },
        { "browser.x.cmd", "x" },
        { "remote.origin.url", "https://example.invalid/x.git" },
      }
      local added = {}
      for i, pair in ipairs(keys) do
        local root = repo(t, "r" .. i)
        t.git(root, "config", "--local", pair[1], pair[2])
        local sets = approval_set(t)
        local lg = lazygit(t)
        lg.open()
        close_floats()
        if sets[1] and vim.list_contains(relative(sets[1].files, root), ".git/config") then
          added[#added + 1] = pair[1]
        end
        package.loaded["core.lazygit"] = nil
      end
      t.eq(added, {})
    end,
  },
  {
    "RULE-041 the set holds lazygit configs, executable hooks and risky origins",
    function(t)
      local root = repo(t)
      t.write(vim.fs.joinpath(root, ".git/lazygit.yml"), "")
      t.write(vim.fs.joinpath(root, ".lazygit.yml"), "")
      t.write(vim.fs.joinpath(root, ".git/hooks/post-checkout"), "#!/bin/sh\n", "755")
      t.write(vim.fs.joinpath(root, ".git/hooks/pre-rebase"), "#!/bin/sh\n", "644")
      t.write(vim.fs.joinpath(root, ".git/hooks/commit-msg.sample"), "#!/bin/sh\n", "755")
      t.write(vim.fs.joinpath(root, "extra.gitconfig"), "[core]\n\tpager = less\n")
      t.git(root, "config", "--local", "include.path", "../extra.gitconfig")
      local sets = approval_set(t)
      local lg = lazygit(t)
      lg.open()
      t.eq(sets[1].key, "lazygit:" .. root)
      t.eq(relative(sets[1].files, root), {
        ".git/config",
        ".git/hooks/post-checkout",
        ".git/lazygit.yml",
        "extra.gitconfig",
      })
    end,
  },
  {
    "RULE-041 Q13 pinned: the repository's own .lazygit.yml is outside the set",
    function(t)
      local root = repo(t)
      t.write(vim.fs.joinpath(root, ".lazygit.yml"), "")
      local sets = approval_set(t)
      local asked = t.ui(2)
      local lg, started = lazygit(t)
      lg.open()
      t.eq({ #sets, #asked, #started }, { 0, 0, 1 })
    end,
  },
  {
    "RULE-041 a parent directory's .lazygit.yml joins the set",
    function(t)
      local parent = t.project("outer")
      t.write(vim.fs.joinpath(parent, ".lazygit.yml"), "")
      local root = t.project("outer/repo")
      t.git(root, "init", "-q")
      vim.fn.chdir(root)
      local sets = approval_set(t)
      lazygit(t).open()
      t.eq(sets[1].files, { vim.fs.joinpath(parent, ".lazygit.yml") })
    end,
  },
  {
    "RULE-041 a worktree is approved under its main worktree",
    function(t)
      local root = repo(t)
      t.git(
        root,
        "-c",
        "user.name=t",
        "-c",
        "user.email=t@t",
        "commit",
        "-q",
        "--allow-empty",
        "-m",
        "x"
      )
      local wt = t.path("wt")
      t.git(root, "worktree", "add", "-q", wt)
      t.write(vim.fs.joinpath(root, ".git/hooks/pre-commit"), "#!/bin/sh\n", "755")
      vim.fn.chdir(wt)
      local sets = approval_set(t)
      lazygit(t).open()
      t.eq(sets[1].key, "lazygit:" .. root)
      t.eq(relative(sets[1].files, root), { ".git/hooks/pre-commit" })
    end,
  },
}
