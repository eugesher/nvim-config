-- :checkhealth myconfig — what this configuration needs from the machine.
--
-- `:checkhealth <name>` looks for `lua/<name>/health.lua`, hence `myconfig/`.
-- A `core/health.lua` would be a second report, `:checkhealth core`, and plain
-- `:checkhealth` would run both.
--
-- Lists are read from the settings that use them where such a list exists
-- (language servers, Mason tools, the debug adapter path, the sessions
-- directory), so the check cannot drift from the config.

local M = {}

local health = vim.health

-- External tools ----------------------------------------------------------------

-- `bin` may list alternatives: Debian ships fd and bat as `fdfind` / `batcat`,
-- and settings/fzf.lua accepts either name.
local REQUIRED = {
  {
    bin = "git",
    min = "2.31.0",
    why = "plugins, gitsigns and neogit; diffview.nvim needs 2.31+",
    install = "sudo apt install git",
  },
  { bin = "rg", why = "live grep in fzf-lua", install = "sudo apt install ripgrep" },
  {
    bin = { "fd", "fdfind" },
    why = "file lists in fzf-lua",
    install = "sudo apt install fd-find && ln -s $(command -v fdfind) ~/.local/bin/fd",
  },
  {
    bin = "fzf",
    above = "0.36.0",
    why = "the engine behind fzf-lua",
    install = "sudo apt install fzf",
  },
  {
    bin = "curl",
    why = "downloads by Mason and the kulala backend",
    install = "sudo apt install curl",
  },
  {
    bin = "node",
    min = "20.0.0",
    why = "TypeScript servers, prettierd and js-debug-adapter",
    install = "https://nodejs.org, or fnm / nvm",
  },
  { bin = "npm", why = "Mason installs npm-based servers with it", install = "comes with Node.js" },
  {
    bin = "tree-sitter",
    min = "0.26.1",
    why = "nvim-treesitter (main) builds parsers with it",
    install = "npm install -g tree-sitter-cli",
  },
  {
    bin = "make",
    why = "builds LuaSnip's jsregexp and telescope-fzf-native.nvim",
    install = "sudo apt install build-essential",
  },
  {
    bin = { "cc", "gcc" },
    why = "C compiler for those builds and for treesitter parsers",
    install = "sudo apt install build-essential",
  },
}

local OPTIONAL = {
  { bin = "mysql", why = "MySQL client for vim-dadbod", install = "sudo apt install mysql-client" },
  {
    bin = "redis-cli",
    why = "Redis through :DB and in a terminal",
    install = "sudo apt install redis-tools",
  },
  { bin = "jq", why = "pretty JSON in kulala responses", install = "sudo apt install jq" },
  {
    bin = "xmllint",
    why = "pretty XML in kulala responses",
    install = "sudo apt install libxml2-utils",
  },
  {
    bin = { "bat", "batcat" },
    why = "highlighted picker previews",
    install = "sudo apt install bat && ln -s $(command -v batcat) ~/.local/bin/bat",
  },
  {
    bin = "delta",
    why = "highlighted git diffs in picker previews",
    install = "sudo apt install git-delta",
  },
}

--- The first version number in `<bin> --version`, or nil when the command
--- fails, hangs or prints something unexpected.
local function version_of(bin)
  local ok, result = pcall(function()
    return vim.system({ bin, "--version" }, { text = true }):wait(3000)
  end)
  if not ok or not result or result.code ~= 0 then
    return nil
  end
  local raw = ((result.stdout or "") .. (result.stderr or "")):match("(%d+%.%d+[%.%d]*)")
  return raw and vim.version.parse(raw, { strict = false }) or nil
end

local function check_tool(tool, report)
  local names = type(tool.bin) == "table" and tool.bin or { tool.bin }
  local found
  for _, name in ipairs(names) do
    if vim.fn.executable(name) == 1 then
      found = name
      break
    end
  end
  if not found then
    report(("%s not found — %s"):format(names[1], tool.why), { "Install: " .. tool.install })
    return
  end

  local label = found == names[1] and found or ("%s (as `%s`)"):format(names[1], found)
  if not tool.min and not tool.above then
    health.ok(("%s — %s"):format(label, tool.why))
    return
  end
  local wanted = tool.min and (">= " .. tool.min) or ("> " .. tool.above)
  local version = version_of(found)
  if not version then
    health.warn(("%s: could not read its version, %s is needed"):format(label, wanted))
    return
  end
  local good = tool.min and vim.version.ge(version, tool.min)
    or (tool.above ~= nil and vim.version.gt(version, tool.above))
  if good then
    health.ok(("%s %s — %s"):format(label, tostring(version), tool.why))
  else
    report(
      ("%s %s is too old, %s is needed — %s"):format(label, tostring(version), wanted, tool.why),
      { "Upgrade: " .. tool.install }
    )
  end
end

-- Sections ----------------------------------------------------------------------

local function check_neovim()
  health.start("Neovim")
  local v = vim.version()
  local version = ("%d.%d.%d"):format(v.major, v.minor, v.patch)
  if vim.fn.has("nvim-0.12") == 1 then
    health.ok("Neovim " .. version)
  else
    health.error(
      "Neovim " .. version .. " — this config needs 0.12+",
      { "sudo snap install nvim --classic" }
    )
  end
  if vim.loader.enabled then
    health.ok("vim.loader is enabled (Lua bytecode cache)")
  else
    health.warn(
      "vim.loader is disabled: startup is slower",
      { "init.lua calls vim.loader.enable()" }
    )
  end
  if vim.o.termguicolors then
    health.ok("'termguicolors' is on")
  else
    health.warn("'termguicolors' is off: the colorscheme falls back to 256 colors")
  end
  if vim.o.inccommand == "nosplit" then
    health.ok("'inccommand' is nosplit (live preview of inc-rename)")
  else
    health.warn(
      ("'inccommand' is %q: rename has no live preview"):format(vim.o.inccommand),
      { "core/options.lua sets it to nosplit" }
    )
  end
  if vim.tbl_contains(vim.opt.sessionoptions:get(), "localoptions") then
    health.ok("'sessionoptions' contains localoptions (auto-session)")
  else
    health.warn(
      "'sessionoptions' lacks localoptions: restored buffers lose filetype settings and keymaps",
      { "core/options.lua adds it" }
    )
  end
end

local function check_tools()
  health.start("Required tools")
  for _, tool in ipairs(REQUIRED) do
    check_tool(tool, health.error)
  end
  health.start("Optional tools")
  for _, tool in ipairs(OPTIONAL) do
    check_tool(tool, health.warn)
  end
end

local function check_mason()
  health.start("Mason packages")
  local ok, registry = pcall(require, "mason-registry")
  if not ok then
    health.error("mason.nvim cannot be loaded", { ":Lazy install" })
    return
  end

  -- Language servers by their vim.lsp names, translated to Mason package names.
  local packages = {}
  local mapped, to_package = pcall(function()
    return require("mason-lspconfig").get_mappings().lspconfig_to_package
  end)
  -- On a fresh machine the mapping stays empty until Mason has downloaded its
  -- registry; guessing the package from the server name would report an
  -- installed `lua-language-server` as a missing `lua_ls`.
  for _, server in ipairs(require("settings.lsp").servers) do
    local name = mapped and to_package and to_package[server]
    if name then
      packages[#packages + 1] = { name = name, role = "language server " .. server }
    else
      health.warn(
        ("%s: no Mason package is known for it yet — the registry has not been downloaded"):format(
          server
        ),
        { ":MasonUpdate, then run :checkhealth myconfig again" }
      )
    end
  end
  for _, tool in ipairs(require("settings.lsp.mason").extra_tools) do
    packages[#packages + 1] = { name = tool, role = "tool" }
  end

  for _, package in ipairs(packages) do
    local installed_ok, installed = pcall(registry.is_installed, package.name)
    if installed_ok and installed then
      health.ok(("%s (%s)"):format(package.name, package.role))
    elseif installed_ok then
      health.error(("%s is not installed (%s)"):format(package.name, package.role), {
        "Restart nvim and wait: missing packages are installed on startup",
        ":MasonInstall " .. package.name,
      })
    else
      health.warn(("%s: the Mason registry could not be read"):format(package.name), { ":Mason" })
    end
  end
end

local PARSERS = {
  { "typescript" },
  { "tsx" },
  { "javascript" },
  { "http", "kulala.nvim cannot parse requests without it" },
  { "sql" },
  { "yaml" },
  { "dockerfile" },
  { "lua" },
  { "markdown" },
}

local function check_parsers()
  health.start("Treesitter parsers")
  for _, parser in ipairs(PARSERS) do
    local ok, loaded = pcall(vim.treesitter.language.add, parser[1])
    if ok and loaded then
      health.ok(parser[1])
    else
      health.error(
        parser[1] .. " parser is missing" .. (parser[2] and (" — " .. parser[2]) or ""),
        { ":TSInstall " .. parser[1] }
      )
    end
  end
end

-- The nearest existing directory at or above `path` is writable.
local function can_create(path)
  local dir = path
  while dir and vim.fn.isdirectory(dir) == 0 do
    local parent = vim.fs.dirname(dir)
    if parent == dir then
      return false
    end
    dir = parent
  end
  return dir ~= nil and vim.fn.filewritable(dir) == 2
end

local function check_files()
  health.start("Files kept across ./install.sh")
  local config = vim.fs.normalize(vim.fn.stdpath("config"))
  -- install.sh replaces ~/.config/nvim wholesale: nothing below must live there.
  local function outside_config(label, path)
    path = vim.fs.normalize(path)
    if path == config or path:sub(1, #config + 1) == config .. "/" then
      health.error(
        ("%s is inside %s and is lost on every ./install.sh: %s"):format(label, config, path)
      )
      return false
    end
    return true
  end

  local db_ui = vim.g.db_ui_save_location or (vim.fn.stdpath("data") .. "/db_ui")
  if outside_config("vim-dadbod-ui storage", db_ui) then
    if vim.fn.isdirectory(db_ui) == 1 then
      health.ok("vim-dadbod-ui connections and saved queries: " .. db_ui)
    else
      health.info(
        ("vim-dadbod-ui storage %s does not exist yet: the first :DBUIAddConnection or saved query creates it"):format(
          db_ui
        )
      )
    end
  end

  local codebook = (vim.env.XDG_CONFIG_HOME or (vim.uv.os_homedir() .. "/.config"))
    .. "/codebook/codebook.toml"
  if outside_config("codebook dictionary", codebook) then
    if vim.uv.fs_stat(codebook) then
      health.ok("codebook dictionary: " .. codebook)
    else
      health.warn(
        "codebook dictionary is missing: codebook runs with its defaults, which check node_modules and dist too — "
          .. codebook,
        { "./install.sh creates it (an existing file is never overwritten)" }
      )
    end
  end

  local sessions = require("settings.autosession").opts.root_dir:gsub("/+$", "")
  if outside_config("sessions", sessions) then
    if vim.fn.isdirectory(sessions) == 1 then
      if vim.fn.filewritable(sessions) == 2 then
        health.ok("sessions are writable: " .. sessions)
      else
        health.error("sessions directory is not writable: " .. sessions)
      end
    elseif can_create(sessions) then
      health.ok("sessions directory can be created: " .. sessions)
    else
      health.error("sessions directory cannot be created: " .. sessions)
    end
  end
end

local function check_font()
  health.start("Font")
  if require("user.settings").ui.nerd_font then
    health.ok(
      "ui.nerd_font = true — the terminal is marked as using a Nerd Font v3 (Neovim cannot see the font itself)"
    )
  else
    health.warn("ui.nerd_font = false: icons will show as boxes or question marks", {
      "Install a Nerd Font from https://www.nerdfonts.com and select it in the terminal",
      "Then set ui.nerd_font = true in lua/user/settings.lua",
    })
  end
end

local function check_debug_adapter()
  health.start("Debug adapter")
  local server = require("settings.dap").server_path()
  if vim.uv.fs_stat(server) then
    health.ok("js-debug-adapter: " .. server)
  else
    health.error(
      "js-debug-adapter is missing — Node and TypeScript debugging cannot start: " .. server,
      { ":MasonInstall js-debug-adapter" }
    )
  end
end

function M.check()
  check_neovim()
  check_tools()
  check_mason()
  check_parsers()
  check_files()
  check_font()
  check_debug_adapter()
end

return M
