-- ~/.config/nvim/lua/lazy-bootstrap.lua
-- Installs lazy.nvim (the plugin manager) on first run and loads all plugin specs.

-- Path where lazy.nvim will be installed
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

-- Clone lazy.nvim from GitHub if it is not already present
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone",
    "--filter=blob:none",                           -- Partial clone to save bandwidth
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",                              -- Use the stable release branch
    lazypath,
  })
end

-- Prepend lazy.nvim to the runtime path (Neovim's module search path)
vim.opt.rtp:prepend(lazypath)

-- Initialize lazy.nvim: load every plugin spec from lua/plugins/
require("lazy").setup("plugins", {
  checker = {
    enabled = true,   -- Periodically check for plugin updates
    notify = false,   -- Don't notify when updates are available
  },
  change_detection = {
    notify = false,   -- Don't notify on config file changes
  },
  rocks = {
    enabled = false, -- No plugins require luarocks; disable support entirely
  },
})
