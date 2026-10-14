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
  root = vim.fn.stdpath("data") .. "/lazy",
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  defaults = {
    lazy = true,
    version = false,
  },
  install = {
    missing = true,
    colorscheme = user.colorscheme.enabled and { "catppuccin", "habamax" } or { "default" },
  },
  checker = { enabled = false },
  change_detection = { enabled = false, notify = false },
  performance = {
    cache = { enabled = true },
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "zipPlugin", "netrwPlugin" },
    },
  },
  ui = {
    border = user.ui.border,
    backdrop = 100,
  },
  rocks = { enabled = false },
  git = { timeout = 120 },
})
