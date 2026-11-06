local ALLOW, DENY = 1, 2

local function tsserver_project(t, name)
  return t.project(name or "p", {
    ["package.json"] = "{}",
    ["node_modules/typescript/lib/tsserver.js"] = "",
    ["src/a.ts"] = "",
  })
end

local function vtsls_init(root)
  local vtsls = require("settings.lsp.servers.vtsls")
  local config = { root_dir = root, settings = { vtsls = { autoUseWorkspaceTsdk = "unset" } } }
  vtsls.config.before_init({}, config)
  return config.settings.vtsls.autoUseWorkspaceTsdk
end

local function eslint_project(t, name)
  return t.project(name or "p", {
    ["package.json"] = "{}",
    ["eslint.config.js"] = "",
    ["node_modules/eslint/package.json"] = "{}",
    ["src/a.ts"] = "",
  })
end

local function lspconfig_root(t, root)
  local file = t.write(
    t.path("lsp/eslint.lua"),
    ("return { root_dir = function(_, on_dir) on_dir(%q) end }"):format(root)
  )
  local real = vim.api.nvim_get_runtime_file
  t.stub(vim.api, "nvim_get_runtime_file", function(name, all)
    if name == "lsp/eslint.lua" then
      return { file }
    end
    return real(name, all)
  end)
end

local function eslint_root_dir(t, root)
  local eslint = require("settings.lsp.servers.eslint")
  local buf = t.buffer(vim.fs.joinpath(root, "src/a.ts"))
  local got = {}
  eslint.config.root_dir(buf, function(dir)
    got[#got + 1] = dir
  end)
  t.wait(function()
    return #got > 0
  end, 300)
  return got, eslint
end

local function conform(t, formatters)
  package.loaded.conform = {
    list_formatters = function()
      return vim.tbl_map(function(name)
        return { name = name }
      end, formatters)
    end,
  }
  return require("settings.formatting.conform")
end

local function sha256(path)
  return vim.fn.sha256(table.concat(vim.fn.readfile(path, "b"), "\n"))
end

return {
  {
    "RULE-015 vtsls takes the workspace TypeScript in an allowed root",
    function(t)
      local root = tsserver_project(t)
      t.ui(ALLOW)
      t.eq(vtsls_init(root), true)
    end,
  },
  {
    "RULE-015 vtsls keeps its bundled TypeScript when the root is denied",
    function(t)
      local root = tsserver_project(t)
      t.ui(DENY)
      t.eq(vtsls_init(root), false)
    end,
  },
  {
    "RULE-015 vtsls keeps its bundled TypeScript without node_modules/typescript",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}" })
      local asked = t.ui(ALLOW)
      t.eq(vtsls_init(root), false)
      t.eq(#asked, 0, "no prompt without a workspace tsserver")
      t.eq(vtsls_init(nil), false)
    end,
  },
  {
    "RULE-015 vtsls never takes the workspace TypeScript headless",
    function(t)
      local root = tsserver_project(t)
      t.eq(vtsls_init(root), false)
    end,
  },
  {
    "RULE-016 eslint attaches in an allowed root with its own eslint",
    function(t)
      local root = eslint_project(t)
      lspconfig_root(t, root)
      t.ui(ALLOW)
      local got = eslint_root_dir(t, root)
      t.eq(got, { root })
    end,
  },
  {
    "RULE-016 eslint stays off in a denied root",
    function(t)
      local root = eslint_project(t)
      lspconfig_root(t, root)
      t.ui(DENY)
      t.eq(eslint_root_dir(t, root), {})
    end,
  },
  {
    "RULE-016 eslint stays off without node_modules/eslint/package.json",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}", ["src/a.ts"] = "" })
      lspconfig_root(t, root)
      local asked = t.ui(ALLOW)
      t.eq(eslint_root_dir(t, root), {})
      t.eq(#asked, 0)
    end,
  },
  {
    "RULE-016 eslint needs every parent with an eslint config or package.json",
    function(t)
      t.write(t.path("mono/package.json"), "{}")
      local root = eslint_project(t, "mono/apps/api")
      lspconfig_root(t, root)
      t.ui({ DENY, ALLOW })
      t.eq(eslint_root_dir(t, root), {})
      t.eq(t.store()[t.path("mono")].decision, "deny")
    end,
  },
  {
    "RULE-016 a changed fingerprint drops validating messages and restarts eslint",
    function(t)
      local root = eslint_project(t)
      lspconfig_root(t, root)
      t.ui(ALLOW)
      local _, eslint = eslint_root_dir(t, root)
      local sent = {}
      local client = {
        root_dir = root,
        notify = function(_, method)
          sent[#sent + 1] = method
          return true
        end,
        request = function(_, method)
          sent[#sent + 1] = method
          return true
        end,
      }
      eslint.config.on_init(client)
      t.eq(client:notify("textDocument/didChange", {}), true)
      local enabled = {}
      t.stub(vim.lsp, "enable", function(name, on)
        enabled[#enabled + 1] = { name, on }
      end)
      t.write(vim.fs.joinpath(root, "eslint.config.js"), "export default []")
      t.eq(client:notify("textDocument/didChange", {}), false)
      t.eq(client:request("workspace/executeCommand", {}), false)
      t.eq(client:notify("$/cancelRequest", {}), true, "non-validating passes")
      t.wait(function()
        return #enabled == 2
      end)
      t.eq(sent, { "textDocument/didChange", "$/cancelRequest" })
      t.eq(enabled, { { "eslint", false }, { "eslint" } })
    end,
  },
  {
    "RULE-017 format on save runs prettier only in an allowed root",
    function(t)
      local root = t.project("p", { ["package.json"] = "{}", ["src/a.ts"] = "x" })
      local m = conform(t, { "prettierd", "prettier" })
      local buf = t.buffer(vim.fs.joinpath(root, "src/a.ts"))
      t.ui(DENY)
      t.eq(m.opts.format_on_save(buf), nil, "denied")
      package.loaded["core.trust"] = nil
      vim.fn.delete(vim.fs.joinpath(vim.fn.stdpath("state"), "myconfig", "trust.json"))
      m = conform(t, { "prettierd", "prettier" })
      t.ui(ALLOW)
      t.eq(m.opts.format_on_save(buf), {}, "allowed")
    end,
  },
  {
    "RULE-017 a parent with a prettier config must be allowed too",
    function(t)
      t.write(t.path("mono/.prettierrc"), "{}")
      local root = t.project("mono/apps/api", { ["package.json"] = "{}", ["src/a.ts"] = "x" })
      local m = conform(t, { "prettier" })
      local buf = t.buffer(vim.fs.joinpath(root, "src/a.ts"))
      t.ui({ DENY, ALLOW })
      t.eq(m.opts.format_on_save(buf), nil)
    end,
  },
  {
    "RULE-017 a buffer without prettier formats without asking",
    function(t)
      local file = t.write(t.path("p/init.lua"), "x")
      local m = conform(t, { "stylua" })
      local buf = t.buffer(file)
      local asked = t.ui(DENY)
      t.eq(m.opts.format_on_save(buf), {})
      t.eq(#asked, 0)
    end,
  },
  {
    "RULE-017 prettier without a root is refused, <leader>cf says why",
    function(t)
      local file = t.write(t.path("loose/a.ts"), "x")
      local m = conform(t, { "prettier" })
      t.buffer(file)
      t.ui(ALLOW)
      t.eq(m.opts.format_on_save(0), nil)
      local formatted = false
      package.loaded.conform.format = function()
        formatted = true
      end
      local key = vim.iter(m.keys):find(function(spec)
        return spec[1] == "<leader>cf"
      end)
      key[2]()
      t.eq(formatted, false)
      t.ok(t.noted("Format skipped"), vim.inspect(t.notes()))
    end,
  },
  {
    "RULE-020 kulala-core is used only when its SHA-256 matches the pin",
    function(t)
      local core = vim.fs.joinpath(vim.fn.stdpath("data"), "kulala.nvim", "bin", "kulala-core")
      t.write(core, "binary", "755")
      local user = require("user.settings")
      t.stub(user.http, "kulala_core_sha256", sha256(core))
      t.eq(require("settings.http.kulala").opts().kulala_core.path, core)
      package.loaded["settings.http.kulala"] = nil
      package.loaded["core.pin"] = nil
      t.write(core, "tampered", "755")
      local path = require("settings.http.kulala").opts().kulala_core.path
      t.neq(path, core)
      t.ok(path:match("/false$"), path)
      t.ok(t.noted("does not match http.kulala_core_sha256"), vim.inspect(t.notes()))
    end,
  },
  {
    "RULE-020 a missing kulala-core is refused the same way",
    function(t)
      local path = require("settings.http.kulala").opts().kulala_core.path
      t.ok(path:match("/false$"), path)
    end,
  },
  {
    "RULE-020 the pin check is cached by stat and survives a reload",
    function(t)
      local core = t.write(t.path("bin/core"), "binary", "755")
      local pin = require("core.pin")
      t.eq(pin.matches(core, sha256(core), "test-core"), true)
      local calls = 0
      local system = vim.system
      t.stub(vim, "system", function(...)
        calls = calls + 1
        return system(...)
      end)
      package.loaded["core.pin"] = nil
      t.eq(require("core.pin").matches(core, sha256(core), "test-core"), true)
      t.eq(calls, 0, "cached result must not run sha256sum")
      t.eq(require("core.pin").matches(core, ("0"):rep(64), "test-core"), false)
      t.eq(require("core.pin").matches(t.path("bin"), sha256(core), "test-core"), false)
    end,
  },
  {
    "RULE-020 kulala requests ask about the .http file's directory",
    function(t)
      local dir = t.project("api", { ["a.http"] = "GET x", ["http-client.env.json"] = "{}" })
      local ran = 0
      package.loaded["kulala.ui"] = {
        open = function()
          ran = ran + 1
        end,
        open_all = function() end,
        replay = function() end,
      }
      package.loaded.kulala = { setup = function() end }
      require("settings.http.kulala").config(nil, {})
      t.buffer(vim.fs.joinpath(dir, "a.http"))
      local asked = t.ui({ DENY })
      require("kulala.ui").open()
      t.eq({ ran, #asked }, { 0, 1 })
      t.ok(t.store()["kulala:" .. dir], "decision stored under kulala:<dir>")
      t.ok(t.noted("not run"), vim.inspect(t.notes()))
    end,
  },
  {
    "RULE-002 every git Neovim starts runs with core.fsmonitor=false",
    function(t)
      local root = t.project("p")
      t.git(root, "init", "-q")
      t.git(root, "config", "--local", "core.fsmonitor", "true")
      for _, key in ipairs({ "GIT_CONFIG_COUNT", "GIT_CONFIG_KEY_0", "GIT_CONFIG_VALUE_0" }) do
        t.setenv(key, nil)
      end
      dofile(vim.fs.joinpath(vim.env.TEST_REPO, "nvim/lua/core/env.lua"))
      t.eq(vim.trim(t.git(root, "config", "core.fsmonitor")), "false")
      dofile(vim.fs.joinpath(vim.env.TEST_REPO, "nvim/lua/core/env.lua"))
      t.eq(vim.env.GIT_CONFIG_COUNT, "1", "loading twice adds nothing")
    end,
  },
  {
    "RULE-002 existing GIT_CONFIG_* entries are kept",
    function(t)
      t.setenv("GIT_CONFIG_COUNT", "1")
      t.setenv("GIT_CONFIG_KEY_0", "user.name")
      t.setenv("GIT_CONFIG_VALUE_0", "x")
      t.setenv("GIT_CONFIG_KEY_1", nil)
      t.setenv("GIT_CONFIG_VALUE_1", nil)
      dofile(vim.fs.joinpath(vim.env.TEST_REPO, "nvim/lua/core/env.lua"))
      t.eq(
        { vim.env.GIT_CONFIG_COUNT, vim.env.GIT_CONFIG_KEY_1, vim.env.GIT_CONFIG_VALUE_1 },
        { "2", "core.fsmonitor", "false" }
      )
      t.eq(vim.env.GIT_CONFIG_KEY_0, "user.name")
    end,
  },
}
