-- defaults verified against mason.nvim v2.3.1 and mason-lspconfig.nvim v2.3.0-15-g0c5d026 (2026-09-11)
--
-- Mason v2: installer for language servers, debug adapters and formatters.
-- mason-lspconfig v2: `ensure_installed` + `automatic_enable`. The v1 `handlers`
-- / `setup_handlers` API no longer exists: `automatic_enable` calls
-- vim.lsp.enable() for every installed server by itself.

local user = require("user.settings")
local icons = require("settings.icons").packages

local M = {}

-- `:Mason` and friends work without an open file.
M.cmd =
  { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog", "MasonUpdate" }

M.opts = {
  install_root_dir = vim.fn.stdpath("data") .. "/mason",
  PATH = "prepend", -- Mason's bin/ first in $PATH: servers and tools resolve to it
  log_level = vim.log.levels.INFO,
  max_concurrent_installers = 4,
  registries = { "github:mason-org/mason-registry" },
  system_registries = { "github:mason-org/mason-system-registry" },
  registry_cache = {
    refresh = true, -- refresh the registry automatically when it goes stale
    duration = 24 * 60 * 60, -- seconds
  },
  firewall = {
    enabled = false, -- socket.dev firewall for package sources
    auto_managed = true,
  },
  providers = {
    "mason.providers.registry-api",
    "mason.providers.client",
  },
  github = {
    download_url_template = "https://github.com/%s/releases/download/%s/%s",
  },
  pip = {
    upgrade_pip = false,
    install_args = {},
  },
  npm = {
    install_args = {},
  },
  ui = {
    check_outdated_packages_on_open = true,
    border = user.ui.border,
    backdrop = 100, -- no dimming behind the window, same as the lazy.nvim UI
    width = 0.8,
    height = 0.9,
    icons = {
      package_installed = icons.installed,
      package_pending = icons.pending,
      package_uninstalled = icons.uninstalled,
    },
    keymaps = {
      toggle_package_expand = "<CR>",
      install_package = "i",
      update_package = "u",
      check_package_version = "c",
      update_all_packages = "U",
      check_outdated_packages = "C",
      uninstall_package = "X",
      cancel_installation = "<C-c>",
      apply_language_filter = "<C-f>",
      toggle_package_install_log = "<CR>",
      toggle_help = "g?",
    },
  },
}

-- mason-lspconfig.nvim, set up in `config` right after mason itself.
local lspconfig_opts = {
  -- Language servers to install automatically, by their vim.lsp config names
  -- (Mason packages: vtsls, eslint-lsp, lua-language-server, json-lsp,
  -- yaml-language-server, bash-language-server, codebook).
  -- docker-language-server arrives with task 22.
  ensure_installed = { "vtsls", "eslint", "lua_ls", "jsonls", "yamlls", "bashls", "codebook" },
  -- The default, stated explicitly: every installed server gets vim.lsp.enable().
  -- Harmless next to the explicit list in settings/lsp/init.lua: enable() is idempotent.
  automatic_enable = true,
}

-- Non-LSP tools. mason-lspconfig only knows language servers, so these are
-- checked on startup and installed when missing — a few lines instead of
-- another plugin (mason-tool-installer).
-- prettier is the fallback when prettierd is missing and serves files outside
-- projects; inside a project conform and prettierd use the project's own Prettier.
-- js-debug-adapter is the debug adapter for Node and TypeScript (settings/dap.lua).
M.extra_tools = { "prettierd", "prettier", "stylua", "js-debug-adapter" }

local function ensure_extra_tools()
  local registry = require("mason-registry")
  local missing = vim.tbl_filter(function(name)
    return not registry.is_installed(name)
  end, M.extra_tools)
  if #missing == 0 then
    return -- the usual case: no registry access at all
  end
  registry.refresh(function()
    vim.notify("Mason: installing " .. table.concat(missing, ", "), vim.log.levels.INFO)
    for _, name in ipairs(missing) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok then
        pcall(pkg.install, pkg)
      else
        vim.notify(("Mason: unknown package %q"):format(name), vim.log.levels.WARN)
      end
    end
  end)
end

function M.config(_, opts)
  require("mason").setup(opts)
  require("mason-lspconfig").setup(lspconfig_opts)
  ensure_extra_tools()
end

return M
