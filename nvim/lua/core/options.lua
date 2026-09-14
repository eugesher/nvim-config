local user = require("user.settings")
local opt = vim.opt

opt.expandtab = true
opt.shiftwidth = user.editor.indent_width
opt.tabstop = user.editor.indent_width
opt.softtabstop = user.editor.indent_width
opt.smartindent = true
opt.breakindent = true

opt.number = true
opt.relativenumber = user.editor.relative_number
opt.signcolumn = "yes"
opt.cursorline = true
opt.termguicolors = true
opt.showmode = false
opt.laststatus = 3
opt.cmdheight = 1
opt.pumheight = 10
opt.scrolloff = user.editor.scrolloff
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"
opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣", extends = "›", precedes = "‹" }
opt.fillchars = { eob = " ", fold = " ", foldsep = " ", diff = "╱" }
opt.winborder = user.ui.border

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.inccommand = "nosplit"

opt.undofile = true
opt.undolevels = 10000
opt.swapfile = false
opt.backup = false
opt.updatetime = 200
opt.timeoutlen = 400
opt.confirm = true

vim.schedule(function()
  opt.clipboard = "unnamedplus"
end)

opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldtext = ""

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

opt.mouse = "a"
opt.completeopt = { "menu", "menuone", "noselect", "popup" }
opt.shortmess:append("cI")
opt.virtualedit = "block"
opt.wildmode = { "longest:full", "full" }
