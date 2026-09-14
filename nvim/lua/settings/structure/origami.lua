local user = require("user.settings")

local M = {}

M.event = "VeryLazy"

M.which_key = {
  { "zF", desc = "Create fold for [count] lines", mode = "n" },
  { "zX", desc = "Re-apply foldlevel", mode = "n" },
  { "zn", desc = "Disable folding", mode = "n" },
  { "zN", desc = "Enable folding", mode = "n" },
  { "zj", desc = "Next fold start", mode = { "n", "x", "o" } },
  { "zk", desc = "Previous fold end", mode = { "n", "x", "o" } },
  { "[z", desc = "Start of current fold", mode = { "n", "x", "o" } },
  { "]z", desc = "End of current fold", mode = { "n", "x", "o" } },
}

M.opts = {
  useLspFoldsWithTreesitterFallback = {
    enabled = false,
    foldmethodIfNeitherIsAvailable = "indent",
  },
  pauseFoldsOnSearch = true,
  foldtext = {
    enabled = true,
    padding = {
      character = " ",
      width = 3,
      hlgroup = nil,
    },
    lineCount = {
      template = "%d lines",
      hlgroup = "Comment",
    },
    diagnosticsCount = true,
    gitsignsCount = true,
    disableOnFt = {
      "NeogitStatus",
      "NeogitCommitView",
      "NeogitCommitSelectView",
      "NeogitDiffView",
      "NeogitLogView",
      "NeogitReflogView",
      "NeogitRefsView",
      "NeogitStashView",
      "NeogitGitCommandHistory",
    },
  },
  autoFold = {
    enabled = #user.folding.auto_fold_kinds > 0,
    kinds = user.folding.auto_fold_kinds,
  },
  foldKeymaps = {
    setup = false,
    closeOnlyOnFirstColumn = false,
    scrollLeftOnCaret = false,
  },
}

return M
