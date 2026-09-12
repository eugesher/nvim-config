-- Editor options. Only Neovim itself — plugin settings live in settings/*.

local user = require("user.settings")
local opt = vim.opt

-- Indentation -----------------------------------------------------------------
opt.expandtab = true -- insert spaces instead of <Tab>
opt.shiftwidth = user.editor.indent_width -- width of one indent step (>>, <<, ==)
opt.tabstop = user.editor.indent_width -- display width of a real <Tab>
opt.softtabstop = user.editor.indent_width -- <Tab>/<BS> in insert mode move this far
opt.smartindent = true -- auto-indent after `{` etc. until a treesitter parser takes over
opt.breakindent = true -- wrapped lines keep the indent of their first line

-- Interface -------------------------------------------------------------------
opt.number = true
opt.relativenumber = user.editor.relative_number
opt.signcolumn = "yes" -- always reserve the column: no text shift when signs appear
opt.cursorline = true
opt.termguicolors = true
opt.showmode = false -- the mode is shown by the status line
opt.laststatus = 3 -- one global status line instead of one per window
opt.cmdheight = 1
opt.pumheight = 10 -- max items in the completion popup
opt.scrolloff = user.editor.scrolloff
opt.sidescrolloff = 8
opt.splitright = true -- :vsplit opens to the right
opt.splitbelow = true -- :split opens below
opt.splitkeep = "screen" -- keep text in place when splits open/close/resize
opt.wrap = false
opt.list = true -- render invisible characters according to 'listchars'
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "╱" }
opt.winborder = user.ui.border -- default border of every floating window (0.11+)

-- Search ----------------------------------------------------------------------
opt.ignorecase = true
opt.smartcase = true -- ...unless the pattern contains uppercase
opt.hlsearch = true
opt.incsearch = true
-- Live preview of :substitute in the buffer. Required by inc-rename.
opt.inccommand = "nosplit"

-- Files -----------------------------------------------------------------------
opt.undofile = true -- persistent undo across sessions
opt.undolevels = 10000
opt.swapfile = false
opt.backup = false
opt.updatetime = 200 -- CursorHold delay and swap flush; drives LSP highlights, gitsigns
opt.timeoutlen = 400 -- wait for the next key of a mapped sequence
opt.confirm = true -- ask instead of failing on :q with unsaved changes

-- Clipboard -------------------------------------------------------------------
-- Scheduled: setting it probes the clipboard provider, which is slow at startup.
vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

-- Folds -----------------------------------------------------------------------
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99 -- start with everything unfolded
opt.foldtext = "" -- closed fold shows the first line with its highlighting

-- Sessions --------------------------------------------------------------------
-- `localoptions` is required by auto-session.
opt.sessionoptions = {
  "blank",
  "buffers",
  "curdir",
  "folds",
  "help",
  "tabpages",
  "winsize",
  "winpos",
  "terminal",
  "localoptions",
}

-- Misc ------------------------------------------------------------------------
opt.mouse = "a"
opt.completeopt = { "menu", "menuone", "noselect", "popup" }
opt.shortmess:append("cI") -- no ins-completion messages, no intro screen
opt.virtualedit = "block" -- visual-block selection may extend past line end
opt.wildmode = { "longest:full", "full" } -- 1st <Tab>: common prefix + menu, then cycle
