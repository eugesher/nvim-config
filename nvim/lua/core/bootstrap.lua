-- lazy.nvim bootstrap and setup.
-- defaults verified against lazy.nvim v11.17.5 (2026-09-11)

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    -- No UI (headless) means nobody can press a key: exit right away.
    if #vim.api.nvim_list_uis() > 0 then
      vim.fn.getchar()
    end
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local user = require("user.settings")

require("lazy").setup({
  spec = { { import = "plugins" } },
  root = vim.fn.stdpath("data") .. "/lazy", -- where plugins are installed
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- part of the config, committed
  defaults = {
    lazy = true, -- every plugin declares its own trigger (event/ft/cmd/keys)
    version = false, -- track the latest commit; pinning is done by the lockfile
  },
  install = {
    missing = true,
    -- Used by the installer UI on first run; "default" keeps Neovim's own
    -- colorscheme while catppuccin is off (user.colorscheme.enabled).
    colorscheme = user.colorscheme.enabled and { "catppuccin", "habamax" } or { "default" },
  },
  checker = { enabled = false }, -- no background update checks
  change_detection = { enabled = false, notify = false }, -- no auto-reload on config edits
  performance = {
    cache = { enabled = true },
    rtp = {
      -- Bundled runtime plugins this config does not use. netrw is replaced
      -- by neo-tree; `tohtml` is an opt package in 0.12 (listed for safety).
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" },
    },
  },
  ui = {
    border = user.ui.border,
    backdrop = 100, -- 100 = fully transparent, i.e. no dimming behind the window
  },
  rocks = { enabled = false }, -- no plugin in this config needs luarocks
  git = { timeout = 120 }, -- seconds before a git process is killed
})
