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
  ".vscode/launch.json",
  "node_modules/typescript/lib/tsserver.js",
  "node_modules/typescript/lib/_tsserver.js",
  "node_modules/typescript/lib/typescript.js",
  "node_modules/.bin/vscode-eslint-language-server",
  "node_modules/eslint/package.json",
  "node_modules/prettier/package.json",
  "node_modules/.bin/prettier",
  "node_modules/.bin/prettierd",
}

local function git_project(t, name, files)
  local root = t.project(name, files)
  t.git(root, "init", "-q")
  return root
end

return {
  {
    "RULE-036 fingerprint is a SHA-256 hex digest",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      t.ok(t.fingerprint(root):match("^%x+$") and #t.fingerprint(root) == 64)
    end,
  },
  {
    "RULE-036 allowed root is trusted until a root file changes",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      local trust = require("core.trust")
      t.ok(t.with_ui(1, function()
        return trust.allowed(root)
      end))
      t.eq(trust.trusted(root), true)
      t.write(vim.fs.joinpath(root, "package.json"), '{"scripts":{}}')
      t.eq(trust.trusted(root), false)
    end,
  },
  {
    "RULE-036 a file outside the fingerprint list keeps the fingerprint",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}", ["src/a.ts"] = "a" })
      local before = t.fingerprint(root)
      t.write(vim.fs.joinpath(root, "src/a.ts"), "b")
      t.write(vim.fs.joinpath(root, "README.md"), "x")
      t.eq(t.fingerprint(root), before)
    end,
  },
  {
    "RULE-036 timestamps alone never change the fingerprint",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}", ["yarn.lock"] = "y" })
      local before = t.fingerprint(root)
      for i = 1, 5 do
        for _, name in ipairs({ "package.json", "yarn.lock" }) do
          vim.uv.fs_utime(vim.fs.joinpath(root, name), 1000000 * i, 2000000 * i)
        end
        t.eq(t.fingerprint(root), before, "after timestamp change " .. i)
      end
    end,
  },
  {
    "RULE-036 every fingerprinted file name changes the fingerprint",
    function(t)
      local empty = t.fingerprint(t.project("empty"))
      local missing = {}
      for i, name in ipairs(fingerprint_files) do
        local root = t.project("p" .. i, { [name] = "x" })
        if t.fingerprint(root) == empty then
          missing[#missing + 1] = name
        end
      end
      t.eq(missing, {}, "files that do not reach the fingerprint")
    end,
  },
  {
    "RULE-036 content changes of a fingerprinted file change the fingerprint",
    function(t)
      local root = t.project("p", { ["node_modules/.bin/prettier"] = "a" })
      local before = t.fingerprint(root)
      t.write(vim.fs.joinpath(root, "node_modules/.bin/prettier"), "b")
      t.neq(t.fingerprint(root), before)
    end,
  },
  {
    "RULE-037 a symlink contributes its real path, not only its content",
    function(t)
      local root = t.project("p", { ["a.json"] = "{}", ["b.json"] = "{}" })
      local link = vim.fs.joinpath(root, "package.json")
      vim.uv.fs_symlink("a.json", link)
      local before = t.fingerprint(root)
      os.remove(link)
      vim.uv.fs_symlink("b.json", link)
      t.neq(t.fingerprint(root), before)
    end,
  },
  {
    "RULE-037 a symlink leaving the root is not read",
    function(t)
      local outside = t.write(t.path("outside.json"), "{}")
      local root = t.project("p")
      vim.uv.fs_symlink(outside, vim.fs.joinpath(root, "package.json"))
      local before = t.fingerprint(root)
      t.write(outside, '{"changed":true}')
      t.eq(t.fingerprint(root), before)
    end,
  },
  {
    "RULE-037 a FIFO in place of a root file is not read",
    function(t)
      local root = t.project("p")
      t.run({ "mkfifo", vim.fs.joinpath(root, "package.json") })
      local fifo = t.fingerprint(root)
      os.remove(vim.fs.joinpath(root, "package.json"))
      t.neq(t.fingerprint(root), fifo)
    end,
  },
  {
    "RULE-037 renaming the project directory changes the fingerprint",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      local before = t.fingerprint(root)
      local moved = t.path("q")
      vim.uv.fs_rename(root, moved)
      t.neq(t.fingerprint(moved), before)
    end,
  },
  {
    "RULE-038 staging a nested tool file changes the fingerprint",
    function(t)
      local root = git_project(t, "p", { ["package.json"] = "{}" })
      t.git(root, "add", "package.json")
      local before = t.fingerprint(root)
      t.write(vim.fs.joinpath(root, "apps/api/.eslintrc.json"), "{}")
      t.eq(t.fingerprint(root), before, "untracked nested config")
      t.git(root, "add", "apps/api/.eslintrc.json")
      t.neq(t.fingerprint(root), before, "staged nested config")
    end,
  },
  {
    "RULE-038 a tracked .env anywhere in the tree is in the digest",
    function(t)
      local root = git_project(t, "p", { ["package.json"] = "{}", ["apps/api/.env"] = "A=1" })
      t.git(root, "add", ".")
      local before = t.fingerprint(root)
      t.write(vim.fs.joinpath(root, "apps/api/.env"), "A=2")
      t.eq(t.fingerprint(root), before, "unstaged change")
      t.git(root, "add", "apps/api/.env")
      t.neq(t.fingerprint(root), before, "staged change")
    end,
  },
  {
    "RULE-038 tracked source files stay out of the digest",
    function(t)
      local root = git_project(t, "p", { ["package.json"] = "{}", ["src/a.ts"] = "a" })
      t.git(root, "add", ".")
      local before = t.fingerprint(root)
      t.write(vim.fs.joinpath(root, "src/a.ts"), "b")
      t.write(vim.fs.joinpath(root, "src/b.ts"), "b")
      t.git(root, "add", ".")
      t.eq(t.fingerprint(root), before)
    end,
  },
  {
    "RULE-038 removing .git changes the fingerprint",
    function(t)
      local root = git_project(t, "p", { ["package.json"] = "{}" })
      t.git(root, "add", "package.json")
      local with_git = t.fingerprint(root)
      vim.fn.delete(vim.fs.joinpath(root, ".git"), "rf")
      package.loaded["core.trust"] = nil
      t.neq(t.fingerprint(root), with_git)
    end,
  },
  {
    "RULE-039 a directory with an untracked marker is its own root",
    function(t)
      local root = git_project(t, "p", { ["package.json"] = "{}", ["apps/api/src/main.ts"] = "" })
      t.git(root, "add", "package.json")
      local file = vim.fs.joinpath(root, "apps/api/src/main.ts")
      local trust = require("core.trust")
      t.eq(trust.root(file), root, "no nested marker")
      t.write(vim.fs.joinpath(root, "apps/api/package.json"), "{}")
      package.loaded["core.trust"] = nil
      t.eq(require("core.trust").root(file), vim.fs.joinpath(root, "apps/api"), "untracked")
    end,
  },
  {
    "RULE-039 a tracked nested marker keeps the git root",
    function(t)
      local root = git_project(t, "p", {
        ["package.json"] = "{}",
        ["apps/api/package.json"] = "{}",
        ["apps/api/src/main.ts"] = "",
      })
      t.git(root, "add", ".")
      t.eq(require("core.trust").root(vim.fs.joinpath(root, "apps/api/src/main.ts")), root)
    end,
  },
  {
    "RULE-039 an untracked tool config is a marker too",
    function(t)
      local root = git_project(t, "p", { ["package.json"] = "{}", ["libs/ui/x.ts"] = "" })
      t.git(root, "add", ".")
      t.write(vim.fs.joinpath(root, "libs/ui/eslint.config.js"), "")
      local got = require("core.trust").root(vim.fs.joinpath(root, "libs/ui/x.ts"))
      t.eq(got, vim.fs.joinpath(root, "libs/ui"))
    end,
  },
  {
    "RULE-039 markers under node_modules never make a root",
    function(t)
      local root = git_project(t, "p", {
        ["package.json"] = "{}",
        ["node_modules/dep/package.json"] = "{}",
        ["node_modules/dep/index.js"] = "",
      })
      t.git(root, "add", "package.json")
      local file = vim.fs.joinpath(root, "node_modules/dep/index.js")
      t.eq(require("core.trust").root(file), root)
    end,
  },
}
