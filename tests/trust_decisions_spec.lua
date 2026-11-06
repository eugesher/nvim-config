local ALLOW, DENY, IGNORE = 1, 2, 3

local function store_file()
  return vim.fs.joinpath(vim.fn.stdpath("state"), "myconfig", "trust.json")
end

local function allowed(t, choice, root)
  return t.with_ui(choice, function()
    return require("core.trust").allowed(root)
  end)
end

return {
  {
    "RULE-001 Allow is stored with the fingerprint and not asked again",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      local ok, asked = allowed(t, ALLOW, root)
      t.eq({ ok, #asked }, { true, 1 })
      t.eq(t.store()[root].decision, "allow")
      ok, asked = allowed(t, DENY, root)
      t.eq({ ok, #asked }, { true, 0 }, "second call must not ask")
    end,
  },
  {
    "RULE-001 Allow is asked again once the fingerprint changes",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      allowed(t, ALLOW, root)
      t.write(vim.fs.joinpath(root, "package.json"), '{"a":1}')
      local ok, asked = allowed(t, DENY, root)
      t.eq({ ok, #asked }, { false, 1 })
      t.ok(asked[1]:find("changed since it was allowed", 1, true), asked[1])
    end,
  },
  {
    "RULE-001 Deny is remembered across fingerprint changes",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      local ok, asked = allowed(t, DENY, root)
      t.eq({ ok, #asked }, { false, 1 })
      t.eq(t.store()[root], { decision = "deny", fingerprint = t.store()[root].fingerprint })
      t.write(vim.fs.joinpath(root, "package.json"), '{"a":1}')
      package.loaded["core.trust"] = nil
      ok, asked = allowed(t, ALLOW, root)
      t.eq({ ok, #asked }, { false, 0 })
    end,
  },
  {
    "RULE-001 Deny of an approval set is remembered across content changes",
    function(t)
      local file = t.write(t.path("set/hook"), "a")
      local trust = require("core.trust")
      local ok, asked = t.with_ui(DENY, function()
        return trust.approve("lazygit:/repo", { file }, "Repository", "runs")
      end)
      t.eq({ ok, #asked }, { false, 1 })
      t.write(file, "b")
      ok, asked = t.with_ui(ALLOW, function()
        return trust.approve("lazygit:/repo", { file }, "Repository", "runs")
      end)
      t.eq({ ok, #asked }, { false, 0 })
    end,
  },
  {
    "RULE-001 Ignore stores nothing and is silent until the fingerprint changes",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      local ok, asked = allowed(t, IGNORE, root)
      t.eq({ ok, #asked }, { false, 1 })
      t.eq(t.store()[root], nil)
      ok, asked = allowed(t, ALLOW, root)
      t.eq({ ok, #asked }, { false, 0 }, "same fingerprint, same session")
      t.write(vim.fs.joinpath(root, "package.json"), '{"a":1}')
      ok, asked = allowed(t, ALLOW, root)
      t.eq({ ok, #asked }, { true, 1 }, "changed fingerprint asks again")
    end,
  },
  {
    "RULE-001 a closed prompt counts as Ignore",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      local ok = allowed(t, 0, root)
      t.eq(ok, false)
      t.eq(t.store()[root], nil)
    end,
  },
  {
    "RULE-013 headless Neovim never allows project code and never asks",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      allowed(t, ALLOW, root)
      local asked = 0
      t.stub(vim.fn, "confirm", function()
        asked = asked + 1
        return ALLOW
      end)
      t.eq(require("core.trust").allowed(root), false)
      t.eq(asked, 0)
    end,
  },
  {
    "RULE-013 trusted() reports the stored decision without asking",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      local trust = require("core.trust")
      t.eq(trust.trusted(root), false, "undecided")
      allowed(t, ALLOW, root)
      t.eq(trust.trusted(root), true, "allowed")
      t.write(vim.fs.joinpath(root, "package.json"), '{"a":1}')
      t.eq(trust.trusted(root), false, "changed")
    end,
  },
  {
    "RULE-013 nil, a missing directory and a git failure are refused",
    function(t)
      local trust = require("core.trust")
      t.eq(allowed(t, ALLOW, nil), false)
      t.eq(allowed(t, ALLOW, t.path("missing")), false)
      local root = t.project("p", { ["package.json"] = "{}" })
      vim.fn.mkdir(vim.fs.joinpath(root, ".git"), "p")
      t.eq(allowed(t, ALLOW, root), false, "broken .git")
      t.ok(t.noted("git failed or took longer"), vim.inspect(t.notes()))
      t.eq(trust.trusted(root), false)
    end,
  },
  {
    "RULE-013 allowed_with_parents needs every parent with a marker below home",
    function(t)
      local parent = t.project("mono", { ["package.json"] = "{}" })
      local child = t.project("mono/apps/api", { ["package.json"] = "{}" })
      local trust = require("core.trust")
      t.eq(trust.parents(child, { "package.json" }), { parent })
      local ok = t.with_ui({ DENY, ALLOW }, function()
        return trust.allowed_with_parents(child, { "package.json" })
      end)
      t.eq(ok, false)
      t.eq(t.store()[parent].decision, "deny")
      t.eq(t.store()[child], nil, "child is not asked once the parent is denied")
    end,
  },
  {
    "RULE-014 the git root is the root of a file inside it",
    function(t)
      local root = t.project("p", { ["src/a.ts"] = "" })
      t.git(root, "init", "-q")
      t.eq(require("core.trust").root(vim.fs.joinpath(root, "src/a.ts")), root)
    end,
  },
  {
    "RULE-014 outside git the nearest tsconfig, package or jsconfig is the root",
    function(t)
      local root = t.project("p", { ["tsconfig.json"] = "{}", ["src/deep/a.ts"] = "" })
      t.eq(require("core.trust").root(vim.fs.joinpath(root, "src/deep/a.ts")), root)
      t.eq(require("core.trust").root(t.write(t.path("loose/a.ts"), "")), nil)
    end,
  },
  {
    "RULE-014 Q9 pinned: outside git a nested package.json makes its own root",
    function(t)
      local top = t.project("a", { ["tsconfig.json"] = "{}", ["b/package.json"] = "{}" })
      local file = t.write(vim.fs.joinpath(top, "b/x.ts"), "")
      t.eq(require("core.trust").root(file), vim.fs.joinpath(top, "b"))
    end,
  },
  {
    "RULE-014 a buffer number resolves like its file name",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}", ["src/a.ts"] = "" })
      local buf = t.buffer(vim.fs.joinpath(root, "src/a.ts"))
      t.eq(require("core.trust").root(buf), root)
    end,
  },
  {
    "RULE-042 approval is one decision over the sorted file set",
    function(t)
      local a = t.write(t.path("set/a"), "a")
      local b = t.write(t.path("set/b"), "b")
      local trust = require("core.trust")
      local ok, asked = t.with_ui(ALLOW, function()
        return trust.approve("lazygit:/repo", { a, b }, "Repository", "runs")
      end)
      t.eq({ ok, #asked }, { true, 1 })
      ok, asked = t.with_ui(DENY, function()
        return trust.approve("lazygit:/repo", { b, a }, "Repository", "runs")
      end)
      t.eq({ ok, #asked }, { true, 0 }, "order does not matter")
      t.write(b, "changed")
      ok, asked = t.with_ui(DENY, function()
        return trust.approve("lazygit:/repo", { a, b }, "Repository", "runs")
      end)
      t.eq({ ok, #asked }, { false, 1 }, "content change asks again")
    end,
  },
  {
    "RULE-042 adding a file to the set asks again",
    function(t)
      local a = t.write(t.path("set/a"), "a")
      local b = t.write(t.path("set/b"), "b")
      local trust = require("core.trust")
      t.with_ui(ALLOW, function()
        return trust.approve("k", { a }, "S", "w")
      end)
      local _, asked = t.with_ui(ALLOW, function()
        return trust.approve("k", { a, b }, "S", "w")
      end)
      t.eq(#asked, 1)
    end,
  },
  {
    "RULE-042 approve refuses without a UI",
    function(t)
      local a = t.write(t.path("set/a"), "a")
      t.eq(require("core.trust").approve("k", { a }, "S", "w"), false)
    end,
  },
  {
    "RULE-067 the store is written owner-only with no temp file left",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      allowed(t, ALLOW, root)
      local file = store_file()
      t.eq(bit.band(vim.uv.fs_stat(file).mode, tonumber("777", 8)), tonumber("600", 8))
      local dir = vim.fs.dirname(file)
      t.eq(bit.band(vim.uv.fs_stat(dir).mode, tonumber("777", 8)), tonumber("700", 8))
      for name in vim.fs.dir(dir) do
        t.ok(not name:match("%.tmp$"), "temp file left: " .. name)
      end
    end,
  },
  {
    "RULE-067 a corrupt store reads as empty and is replaced",
    function(t)
      t.write(store_file(), "{not json")
      local root = t.project("p", { ["package.json"] = "{}" })
      local ok, asked = allowed(t, ALLOW, root)
      t.eq({ ok, #asked }, { true, 1 })
      t.eq(t.store()[root].decision, "allow")
    end,
  },
  {
    "RULE-067 a second decision keeps the first one",
    function(t)
      local a = t.project("a", { ["package.json"] = "{}" })
      local b = t.project("b", { ["package.json"] = "{}" })
      allowed(t, ALLOW, a)
      allowed(t, DENY, b)
      t.eq({ t.store()[a].decision, t.store()[b].decision }, { "allow", "deny" })
    end,
  },
  {
    "RULE-068 :ProjectTrust list shows each decision",
    function(t)
      local a = t.project("a", { ["package.json"] = "{}" })
      allowed(t, ALLOW, a)
      vim.cmd("ProjectTrust list")
      t.ok(t.noted("allow " .. vim.pesc(a)), vim.inspect(t.notes()))
      vim.fn.delete(store_file())
      vim.cmd("ProjectTrust")
      t.ok(t.noted("No project trust decisions"), vim.inspect(t.notes()))
    end,
  },
  {
    "RULE-068 :ProjectTrust forget drops a decision, deny writes one",
    function(t)
      local a = t.project("a", { ["package.json"] = "{}" })
      allowed(t, ALLOW, a)
      vim.cmd("ProjectTrust forget " .. vim.fn.fnameescape(a))
      t.eq(t.store()[a], nil)
      t.ok(t.noted("Forgot "), vim.inspect(t.notes()))
      vim.cmd("ProjectTrust forget " .. vim.fn.fnameescape(a))
      t.ok(t.noted("No decision for "), vim.inspect(t.notes()))
      vim.cmd("ProjectTrust deny " .. vim.fn.fnameescape(a))
      t.eq(t.store()[a], { decision = "deny" })
      t.eq(allowed(t, ALLOW, a), false)
    end,
  },
  {
    "RULE-068 :ProjectTrust takes lazygit: and kulala: keys verbatim",
    function(t)
      local file = t.write(t.path("x"), "x")
      require("core.trust")
      t.with_ui(ALLOW, function()
        return require("core.trust").approve("lazygit:/some/repo", { file }, "S", "w")
      end)
      vim.cmd("ProjectTrust forget lazygit:/some/repo")
      t.eq(t.store()["lazygit:/some/repo"], nil)
      vim.cmd("ProjectTrust deny kulala:/some/dir")
      t.eq(t.store()["kulala:/some/dir"], { decision = "deny" })
    end,
  },
  {
    "RULE-068 :ProjectTrust deny of a missing directory is refused",
    function(t)
      require("core.trust")
      vim.cmd("ProjectTrust deny " .. vim.fn.fnameescape(t.path("missing")))
      t.ok(t.noted("No such directory"), vim.inspect(t.notes()))
      t.eq(t.store(), {})
    end,
  },
}
