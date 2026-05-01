-- ~/.config/nvim/init.lua
-- Entry point. Loads all configuration modules.

-- Set the leader key BEFORE loading any plugins.
-- Leader is a user-defined modifier for custom mappings.
-- Space is the most popular choice because both hands can reach it easily.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Load configuration modules
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.fallback-buf")

-- Bootstrap the plugin manager (installs lazy.nvim on first run)
require("lazy-bootstrap")
