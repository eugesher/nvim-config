-- ~/.config/nvim/lua/config/options.lua
-- Core editor options.

local settings = require("config.user-settings")
local opt = vim.opt

-- Line numbers: absolute + relative.
-- Current line shows the absolute number; other lines show the distance
-- from the cursor (useful for commands like 5j, 12dd).
opt.number = true
opt.relativenumber = false

-- Indentation: width sourced from user-settings (default 2 — standard for Node.js / TypeScript)
opt.tabstop = settings.editor.indent_width -- Width of a tab character
opt.shiftwidth = settings.editor.indent_width -- Width of an auto-indent step
opt.expandtab = true -- Convert tabs to spaces
opt.smartindent = true -- Context-aware auto-indent

-- Search
opt.ignorecase = true -- Case-insensitive search...
opt.smartcase = true -- ...unless the query contains uppercase letters

-- Visual polish
opt.termguicolors = true -- Enable 24-bit true color
opt.signcolumn = "yes" -- Always show the sign column (for LSP diagnostics)
opt.cursorline = true -- Highlight the current line
opt.scrolloff = 8 -- Keep at least 8 lines visible above/below the cursor

-- Window splitting
opt.splitright = true -- New vertical split opens on the right
opt.splitbelow = true -- New horizontal split opens below

-- Clipboard: use the system clipboard (copy/paste to/from the browser)
opt.clipboard = "unnamedplus"

-- Disable swapfile and backups; rely on persistent undo instead
opt.swapfile = false
opt.backup = false
opt.undofile = true -- Persistent undo history across sessions

-- Always prefer Unix line endings (LF) when creating or writing files
opt.fileformats = "unix,dos,mac"

-- Diagnostics: errors first, then warnings, hints, info
vim.diagnostic.config({ severity_sort = true })

-- Timeout for mapped sequences (ms)
opt.timeoutlen = 1000

-- Update interval (ms) — affects responsiveness of plugins like gitsigns
opt.updatetime = 250

-- Disable unused language providers to silence :checkhealth warnings.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
