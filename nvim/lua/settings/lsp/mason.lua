local user = require("user.settings")
local icons = require("settings.icons").packages

local M = {}

M.cmd =
  { "Mason", "MasonInstall", "MasonUninstall", "MasonUninstallAll", "MasonLog", "MasonUpdate" }

M.opts = {
  install_root_dir = vim.fn.stdpath("data") .. "/mason",
  PATH = "prepend",
  log_level = vim.log.levels.INFO,
  max_concurrent_installers = 4,
  registries = { "github:mason-org/mason-registry" },
  system_registries = { "github:mason-org/mason-system-registry" },
  registry_cache = {
    refresh = true,
    duration = 24 * 60 * 60,
  },
  firewall = {
    enabled = false,
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
    backdrop = 100,
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

local lspconfig_opts = {
  ensure_installed = {
    "vtsls",
    "eslint",
    "lua_ls",
    "jsonls",
    "yamlls",
    "bashls",
    "codebook",
    "docker_language_server",
    "dockerls",
  },
  automatic_enable = true,
}

M.extra_tools = { "prettierd", "prettier", "stylua", "js-debug-adapter" }

local function ensure_extra_tools()
  local registry = require("mason-registry")
  local missing = vim.tbl_filter(function(name)
    return not registry.is_installed(name)
  end, M.extra_tools)
  if #missing == 0 then
    return
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
